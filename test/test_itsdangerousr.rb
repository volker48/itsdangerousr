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


class TimedSignerTests < Test::Unit::TestCase
  def setup
    @signer = Itsdangerousr::TimestampSigner.new('secret')
  end

  def test_sign
    signed = @signer.sign('this is a test')
    assert(signed.include?('this is a test'))
    assert(signed.count('.') == 2)
  end

  def test_unsign_no_options
    signed = @signer.sign('this is a test')
    unsigned = @signer.unsign(signed)
    assert(unsigned == 'this is a test')
  end

  def test_sig_error
    signed = @signer.sign('my test')
    other_signer = Itsdangerousr::TimestampSigner.new('other secret')
    assert_raise(Itsdangerousr::BadSignature, "Raise exception on bad signature") {
      other_signer.unsign(signed)
    }
  end

  def test_raises_badtimesignature
    non_timestamp_signed = Itsdangerousr::Signer.new('secret').sign('test')
    assert_raise(Itsdangerousr::BadTimeSignature, "Raise exception on missing timestamp") {
      @signer.unsign(non_timestamp_signed)
    }
  end

end

class TimedSerializerTests < Test::Unit::TestCase

  def setup
    @serializer = Itsdangerousr::TimedSerializer.new('secret')
  end

  def test_not_expired
    original = 'My data'
    payload = @serializer.dumps(original)
    assert_not_equal(payload, original)
    loaded = @serializer.loads(payload, :max_age => 500)
    assert_equal(original, loaded)
  end

  def test_expired
    original = {:message => 'The files are _in_ the computer?'}
    payload = @serializer.dumps(original)
    assert_not_equal(payload, original)
    sleep(2)
    assert_raise(Itsdangerousr::SignatureExpired, "Timestamp should be too old") {
      @serializer.loads(payload, :max_age => 1)
    }
  end



end

class URLSafeTimedSerializerTests < Test::Unit::TestCase

  def setup
    @serializer = Itsdangerousr::URLSafeTimedSerializer.new('secret')
  end

  def test_from_python
      original = {:message => 'this better work'}
      from_python = 'eyJtZXNzYWdlIjoidGhpcyBiZXR0ZXIgd29yayJ9.BuZqLQ.bjbIUg3pAgW4URRFHWkzIrC4OgU'
      loaded = @serializer.loads(from_python, :max_age => 60*60*24*365*100)
      assert_equal(original, loaded)
  end
  
  def test_expired
    original = {:message => 'The files are _in_ the computer?'}
    payload = @serializer.dumps(original)
    assert_not_equal(payload, original)
    sleep(2)
    assert_raise(Itsdangerousr::SignatureExpired, "Timestamp should be too old") {
      @serializer.loads(payload, :max_age => 1)
    }
  end

end


