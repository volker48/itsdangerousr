require 'test/unit'
require 'itsdangerous'

class UtilityTests < Test::Unit::TestCase

  def test_base64_encode
    encoded = base64_encode('this is a long test')
    assert(encoded == 'dGhpcyBpcyBhIGxvbmcgdGVzdA')
  end

  def test_base64_decode
    decoded = base64_decode('dGhpcyBpcyBhIGxvbmcgdGVzdA')
    assert(decoded == 'this is a long test')
  end

  def test_ctc_equal
    assert(constant_time_compare('abc123', 'abc123'))

  end

  def test_ctc_val1_longer
    assert(!constant_time_compare('asdfasdfasdf', 'a'))
  end

  def test_ctc_val2_longer
    assert(!constant_time_compare('a', 'asdf123asdf235a'))
  end

  def test_ctc_empty_string
    assert(constant_time_compare('', ''))
  end

end

class SignerTests < Test::Unit::TestCase
  def setup
    @signer = Signer.new('key')
  end

  def test_derive_key
      sha1 = OpenSSL::Digest.new('sha1')
      expected_digest = sha1.digest('itsdangerous.Signer' + 'signer' + 'key')
      digest = @signer.derive_key()
      assert(expected_digest == digest)
    end
end

class SerializerTests < Test::Unit::TestCase

  def setup
    @serializer = Serializer.new('key')
  end

  def test_dump_payload
    payload = {:message => 'hello', :status => 'ok'}
    dumped = @serializer.dump_payload(payload)
    assert(dumped == '{"message":"hello","status":"ok"}')
  end

  def test_load_payload
    payload = '{"message":"hello","status":"ok"}'
    loaded = @serializer.load_payload(payload)
    assert(loaded[:message] == 'hello')
    assert(loaded[:status] == 'ok')
  end

  def test_dumps
    payload = {:message => 'python rules'}
    dumped = @serializer.dumps(payload)
    signer = Signer.new('key', :salt => 'itsdangerous')
    key = signer.derive_key()
    hmaced = OpenSSL::HMAC.digest(OpenSSL::Digest::SHA1.new, key, '{"message":"python rules"}'.encode('utf-8'))
    encoded = base64_encode(hmaced)
    assert(dumped == "{\"message\":\"python rules\"}.#{encoded}")
  end

end


