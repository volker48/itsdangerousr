require 'test/unit'
require 'itsdangerous'

class WantBytesTests < Test::Unit::TestCase

  # Fake test
  def test_encoding_works
    test_string = 'some secret'
    test_string = test_string.encode('ascii')
    s = want_bytes(test_string)
    assert(s.encoding == Encoding::UTF_8, 'Encoding should be utf-8')
  end

  def test_base64_encode
    encoded = base64_encode('this is a long test')
    assert(encoded == 'dGhpcyBpcyBhIGxvbmcgdGVzdA')
  end
end