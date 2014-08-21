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

== Contributing to itsdangerousr
 
* Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet.
* Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it.
* Fork the project.
* Start a feature/bugfix branch.
* Commit and push until you are happy with your contribution.
* Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.
* Please try not to mess with the Rakefile, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.

== Copyright

Copyright (c) 2014 Marcus McCurdy. See LICENSE.txt for
further details.

