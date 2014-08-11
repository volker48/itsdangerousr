require 'json'
require 'base64'
require 'digest/sha1'
require 'digest/hmac'
require 'zlib'


def base64_encode(string)
  Base64.urlsafe_encode64(string).delete('=')
end

def base64_decode(string)
  Base64.urlsafe_decode64(string + '=' * string.length % 4)
end


def constant_time_compare(val1, val2)
  check = val1.bytesize ^ val2.bytesize
  val1.bytes.zip(val2.bytes) { |x, y| check |= x ^ y.to_i }
  check == 0
end


class Signer

  @@default_digest_method = Digest::SHA1
  @@default_key_derivation = 'django-concat'

  def initialize(secret_key, options={})
    defaults = {:salt => 'itsdangerous.Signer', :sep => '.', :key_derivation => nil, :digest_method => nil}
    options = defaults.merge(options)
    @secret_key = secret_key.encode('utf-8')
    @sep = options[:sep].encode('utf-8')
    @salt = options[:salt].encode('utf-8')
    @key_derivation = options[:key_derivation].nil? ? @@default_key_derivation : options[:key_derivation]
    @digest_method = options[:digest_method].nil? ? @@default_digest_method : options[:digest_method]
  end

  def get_signature(value)
    key = derive_key()
    base64_encode(Digest.HMAC.hexdigest(value, key, @digest_method))
  end

  def sign(value)
    value = value.encode('utf-8')
    value + @sep + get_signature(value)
  end

  def derive_key
    case @key_derivation
      when 'concat'
        @digest_method.digest(@salt + @secret_key)
      when 'django-concat'
        @digest_method.digest(@salt + 'signer' + @secret_key)
      when 'hmac'
        hmac = Digest.HMAC.new(@secret_key, @digest_method)
        hmac.update(@salt)
        hmac.digest()
      when 'none'
        @secret_key
      else
        raise TypeError, 'Unknown key derivation method'
    end
  end

  def validate(signed_value)
    begin
      unsign(signed_value)
      true
    rescue BadSignature
      false
    end
  end

  def unsign(signed_value)
    unless signed_value.include?('.')
      raise BadSignature, "No #{@sep} found in signed value"
    end
    value, _, sig = signed_value.rpartition(@sep)
    unless verify_signature(value, sig)
      raise BadSignature, "Signature #{sig} does not match"
    end
  end

  def verify_signature(value, sig)
    sig = base64_decode(sig)
    constant_time_compare(sig, get_signature(value))
  end

end

class BadSignature < StandardError
end

class BadPayload < StandardError

end

class Serializer

  @@default_signer = Signer
  @@default_serializer = JSON

  def initialize(secret_key, options={})
    defaults = {:salt => 'itsdangerous', :serializer => nil, :signer => nil, :signer_kwargs => nil}
    options = defaults.merge(options)
    @secret_key = secret_key
    @salt = options[:salt].encode('utf-8')
    @serializer = options[:serializer].nil? ? @@default_serializer : options[:serializer]
    @signer = options[:signer].nil? ? @@default_signer : options[:signer]
    @signer_kwargs = options[:signer_kwargs].nil? ? {} : options[:signer_kwargs]
  end

  def load_payload(payload, options={})
    defaults = {:serializer => nil}
    options = defaults.merge(options)
    serializer = options[:serializer].nil? ? @serializer : options[:serializer]
    serializer.load(payload.encode('utf-8'))
  end

  def dump_payload(obj)
    @serializer.dump(obj)
  end

  def make_signer(options={})
    defaults = {:salt => nil}
    options = defaults.merge(options)
    salt = options[:salt].nil? ? @salt : options[:salt]
    @signer.new(@secret_key, @signer_kwargs.merge(:salt => salt))
  end

  def dumps(obj, salt=nil)
    payload = dump_payload(obj)
    make_signer(:salt => salt).sign(payload)
  end

  def loads(s, salt=nil)
    s = s.encode('utf-8')
    load_payload(make_signer(:salt => salt).unsign(s))
  end

end

module URLSaferSerializerMixin

  def load_payload(payload)
    decompress = false
    if payload.start_with?('.')
      payload = payload[1..-1]
      decompress = true
    end
    json = base64_decode(payload)
    if decompress
      begin
        json = Zlib.Inflate.inflate(payload)
      rescue => e
        raise BadPayload, "Could not zlib decompress the payload before decoding the payload. #{e}"
      end
      super(json)
    end
  end

  def dump_payload(obj)
    json = super(obj)
    is_compressed = false
    compressed = Zlib.deflate(json)
    if compressed.length < json.length - 1
      json = compressed
      is_compressed = true
    end
    base64d = base64_encode(json)
    base64d.prepend('.') if is_compressed
  end

end

class URLSafeSerializer < Serializer
  include URLSaferSerializerMixin
end


