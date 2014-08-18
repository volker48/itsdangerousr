#It's Dangerous to go alone take this...


[![Build Status](https://travis-ci.org/volker48/itsdangerousr.svg?branch=master)](https://travis-ci.org/volker48/itsdangerousr)

This is a port of Python's [itsdangerous](https://github.com/mitsuhiko/itsdangerous) to Ruby

###Examples

```ruby
  require 'itsdangerousr'

  serializer = Itsdangerousr::URLSafeSerializer.new('super secret key')

  payload = {:message => 'Keep it secret, keep it safe', :status => 'ok'}

  result = serializer.dumps(payload)

  puts result

  # "eyJtZXNzYWdlIjoiS2VlcCBpdCBzZWNyZXQsIGtlZXAgaXQgc2FmZSIsInN0YXR1cyI6Im9rIn0.nzD92ZMbV52tUW-yp9IWTKqYHRo"

  decoded = serializer.loads(result)

  puts decoded

  # {:message=>"Keep it secret, keep it safe", :status=>"ok"}
```
