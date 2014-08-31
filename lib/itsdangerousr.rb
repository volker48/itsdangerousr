require 'json'
require 'base64'
require 'openssl'
require 'time'
require 'zlib'

module Itsdangerousr

  # 2011/01/01 in UTC
  EPOCH = 1293840000

  def self.base64_encode(string)
    Base64.urlsafe_encode64(string).gsub(/=+$/, '')
  end

  def self.base64_decode(string)
    Base64.urlsafe_decode64(string + '=' * (-string.length % 4))
  end


  def self.constant_time_compare(val1, val2)
    check = val1.bytesize ^ val2.bytesize
    val1.bytes.zip(val2.bytes) { |x, y| check |= x ^ y.to_i }
    check == 0
  end

  class SigningAlgorithm

    def get_signature(key, value)
      raise 'Not Implemented'
    end

    def verify_signature(key, value, sig)
      Itsdangerousr.constant_time_compare(sig, get_signature(key, value))
    end

  end

  class HMACAlgorithm < SigningAlgorithm

    def initialize(digest_method=OpenSSL::Digest::SHA1)
      @digest_method = digest_method
    end

    def get_signature(key, value)
      OpenSSL::HMAC.digest(@digest_method.new, key, value)
    end
  end


  class Signer

    def initialize(secret_key, options={})
      defaults = {:salt => 'itsdangerous.Signer', :sep => '.',
                  :key_derivation => 'django-concat',
                  :digest_method => OpenSSL::Digest::SHA1,
                  :algorithm => HMACAlgorithm.new()}
      options = defaults.merge(options)
      @secret_key = secret_key
      @sep = options[:sep]
      @salt = options[:salt]
      @key_derivation = options[:key_derivation]
      @digest_method = options[:digest_method]
      @algorithm = options[:algorithm]
    end

    def get_signature(value)
      key = derive_key()
      sig = @algorithm.get_signature(key, value)
      Itsdangerousr.base64_encode(sig)
    end

    def sign(value)
      value + @sep + get_signature(value)
    end

    def derive_key
      case @key_derivation
        when 'concat'
          @digest_method.digest(@salt + @secret_key)
        when 'django-concat'
          @digest_method.digest(@salt + 'signer' + @secret_key)
        when 'hmac'
          hmac = OpenSSL::HMAC.new(@secret_key, @digest_method)
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
        raise BadSignature.new("Signature #{sig} does not match", value)
      end
      value
    end

    def verify_signature(value, sig)
      key = derive_key()
      sig = Itsdangerousr.base64_decode(sig)
      @algorithm.verify_signature(key, value, sig)
    end

  end

  class TimestampSigner < Signer
    def sign(value)
      timestamp = Itsdangerousr::base64_encode((Time.now.to_i - Itsdangerousr::EPOCH).to_s)
      value = value + @sep + timestamp
      value + @sep + get_signature(value)
    end

    def unsign(value, options={})
      defaults = {:max_age => nil, :return_timestamp => false}
      options = defaults.merge(options)
      @max_age = options[:max_age]
      @return_timestamp = options[:return_timestamp]
      begin
        result = super(value)
        sig_error = nil
      rescue BadSignature => e
        sig_error = e
        if e.payload.nil?
          result = e.paylod
        else
          result = ''
        end

      end

      unless result.include?(@sep)
        if sig_error
          raise sig_error
        end
        raise BadTimeSignature, 'Timestamp missing'
      end

      value, _, timestamp = result.rpartition(@sep)

      begin
        timestamp = Itsdangerousr::base64_decode(timestamp).to_i
      rescue StandardError
        timestamp = nil
      end

      unless sig_error.nil?
        raise BadTimeSignature.new(sig_error.message, value, timestamp)
      end

      if timestamp.nil?
        raise BadTimeSignature.new('Malformed timestamp', value)
      end

      unless @max_age.nil?
        age = (Time.now.to_i - Itsdangerousr::EPOCH) - timestamp.to_i
        if age > @max_age
          raise SignatureExpired.new("Signature age %s > %s seconds" % [age, @max_age], value,)
        end
      end

      if @return_timestamp
        return value, timestamp
      end
      value
    end
  end

  class BadSignature < StandardError

    attr_reader :payload

    def initialize(message, payload=nil)
      super(message)
      @payload = payload
    end

  end

  class BadTimeSignature < BadSignature
    def initialize (message, payload=nil, date_signed=nil)
      super(message, payload)
      @date_signed = date_signed
    end
  end

  class SignatureExpired < BadTimeSignature

  end

  class BadPayload < StandardError

  end

  class Serializer

    def initialize(secret_key, options={})
      defaults = {:salt => 'itsdangerous', :serializer => JSON,
                  :signer => Signer, :signer_kwargs => {}}
      options = defaults.merge(options)
      @secret_key = secret_key
      @salt = options[:salt]
      @serializer = options[:serializer]
      @signer = options[:signer]
      @signer_kwargs = options[:signer_kwargs]
    end

    def load_payload(payload, options={})
      defaults = {:serializer => @serializer}
      options = defaults.merge(options)
      serializer = options[:serializer]
      serializer.load(payload, nil, :symbolize_names => true)
    end

    def dump_payload(obj)
      @serializer.dump(obj)
    end

    def make_signer(options={})
      defaults = {:salt => @salt}
      options = defaults.merge(options)
      @signer.new(@secret_key, @signer_kwargs.merge(:salt => options[:salt]))
    end

    def dumps(obj, salt=@salt)
      payload = dump_payload(obj)
      make_signer(:salt => salt).sign(payload)
    end

    def loads(s, salt=@salt)
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
      json = Itsdangerousr.base64_decode(payload)
      if decompress
        begin
          json = Zlib::Inflate.inflate(json)
        rescue => e
          raise BadPayload, "Could not zlib decompress the payload before decoding the payload. #{e}"
        end
      end
      super(json)
    end

    def dump_payload(obj)
      json = super(obj)
      is_compressed = false
      compressed = Zlib::Deflate.deflate(json)
      if compressed.length < json.length - 1
        json = compressed
        is_compressed = true
      end
      base64d = Itsdangerousr.base64_encode(json)
      base64d.prepend('.') if is_compressed
      base64d
    end

  end

  class TimedSerializer < Serializer

    def initialize(secret_key, options={:signer => TimestampSigner})
      super(secret_key, options)
    end

    def loads(s, options={})
      defaults = {:max_age=>nil, :return_timestamp=>false, :salt=>@salt}
      options = defaults.merge(options)
      signer = make_signer(:salt => options[:salt])
      base64d, timestamp = signer.unsign(s, options)
      payload = load_payload(base64d)
      if options[:return_timestamp]
        return payload, timestamp
      end
      payload
    end

  end

  class URLSafeSerializer < Serializer
    include URLSaferSerializerMixin
  end

end
