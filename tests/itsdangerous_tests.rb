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


class SerializerTests < Test::Unit::TestCase
  def test_dump_payload
    payload = {:message => 'hello', :status => 'ok'}
    s = Serializer.new('key')
    dumped = s.dump_payload(payload)
    assert(dumped == '{"message":"hello","status":"ok"}')
  end

end