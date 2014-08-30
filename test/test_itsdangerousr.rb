require_relative 'helper'

class UtilityTests < Test::Unit::TestCase

  def test_base64_encode
    encoded = Itsdangerousr.base64_encode('this is a long test')
    assert(encoded == 'dGhpcyBpcyBhIGxvbmcgdGVzdA')
  end

  def test_base64_decode
    decoded = Itsdangerousr.base64_decode('dGhpcyBpcyBhIGxvbmcgdGVzdA')
    assert(decoded == 'this is a long test')
  end

  def test_ctc_equal
    assert(Itsdangerousr.constant_time_compare('abc123', 'abc123'))

  end

  def test_ctc_val1_longer
    assert(!Itsdangerousr.constant_time_compare('asdfasdfasdf', 'a'))
  end

  def test_ctc_val2_longer
    assert(!Itsdangerousr.constant_time_compare('a', 'asdf123asdf235a'))
  end

  def test_ctc_empty_string
    assert(Itsdangerousr.constant_time_compare('', ''))
  end

end

class SignerTests < Test::Unit::TestCase
  def setup
    @signer = Itsdangerousr::Signer.new('key')
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
    @serializer = Itsdangerousr::Serializer.new('key')
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
    signer = Itsdangerousr::Signer.new('key', :salt => 'itsdangerous')
    key = signer.derive_key()
    hmaced = OpenSSL::HMAC.digest(OpenSSL::Digest::SHA1.new, key, '{"message":"python rules"}'.encode('utf-8'))
    encoded = Itsdangerousr.base64_encode(hmaced)
    assert(dumped == "{\"message\":\"python rules\"}.#{encoded}")
  end

  def test_dumps_loads
    test_cases = [['a', 'list'], 'a string', 'a unicode string \u2019', {:a => 'dictionary'}, 42, 42.5]
    test_cases.each do |test_case|
      dumped = @serializer.dumps(test_case)
      assert_not_equal(test_case, dumped)
      loaded = @serializer.loads(dumped)
      assert_equal(test_case, loaded)
    end
  end

end

class URLSafeSerializerTests < Test::Unit::TestCase

  def setup
    @serializer = Itsdangerousr::URLSafeSerializer.new('key')
    @short_payload = {:message => 'This is a test', :status => 'ok'}
    @long_payload = {:message => 'This is a longer message so we can see if it will compress something long', :lift => 'do you even, bro?', :status => 'copacetic'}
  end

  def test_dump_payload_short
    dumped = @serializer.dumps(@short_payload)
    assert(dumped[0] != '.')
    assert(dumped.include?('.'))
  end

  def test_dumps_loads
    test_cases = [['a', 'list'], 'a string', 'a unicode string \u2019',
                  {:a => 'dictionary'}, 42, 42.5,
                  {:message => 'this is a longer dict want to test out compression',
                   :status => 'great thanks for asking'}]
    test_cases.each do |test_case|
      dumped = @serializer.dumps(test_case)
      assert_not_equal(test_case, dumped)
      loaded = @serializer.loads(dumped)
      assert_equal(test_case, loaded)
    end
  end

  def test_load_from_python
    key = "\x18j\xe4iiw\xdd\xcb\xacF\x1a\xc0\x17\xc5\x8b\xe7"
    plain_text = 'this is something i want secure'
    from_python = 'InRoaXMgaXMgc29tZXRoaW5nIGkgd2FudCBzZWN1cmUi.8frS9vZcZJCSLAW7zK-gGC68JKM'
    s = Itsdangerousr::URLSafeSerializer.new(key)
    loaded = s.loads(from_python)
    assert_equal(plain_text, loaded)
  end

end


