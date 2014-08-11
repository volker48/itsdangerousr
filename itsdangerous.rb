require 'json'
require 'base64'

def want_bytes(s, encoding='utf-8')
  if s.kind_of? String
    s = s.encode(encoding)
  end
  s
end

def base64_encode(string)
  string = want_bytes(string)
  Base64.urlsafe_encode64(string).delete('=')
end

def base64_decode(string)
  string = want_bytes(string)
  Base64.urlsafe_decode64(string)
end

#class URLSaferSerializerMixin
#
#end
#
#class Serializer
#
#  def initialize(secret_key, salt='itsdangerous', serializer=nil, signer=nil, signer_kwargs=nil)
#    @secret_key = secret_key
#  end
#
#end
#
#class URLSafeSerializer < URLSaferSerializerMixin < Serializer
#
#end