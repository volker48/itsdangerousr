# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name = "itsdangerousr"
  spec.version = '1.0.0'
  spec.authors = ["Marcus McCurdy"]
  spec.email = ["marcus.mccurdy@gmail.com"]
  spec.summary = %q{Python's itsdangerous ported to Ruby}
  spec.description = %q{Sometimes you just want to send some data to untrusted
    environments. But how to do this safely? The trick involves signing.
    Given a key only you know, you can cryptographically sign your data and hand
    it over to someone else. When you get the data back you can easily ensure
    that nobody tampered with it.}
  spec.homepage = "http://github.com/volker48/itsdangerousr/"
  spec.license = "MIT"
  spec.files = ['lib/itsdangerousr.rb']
  spec.test_files = ['tests/itsdangerousr_tests.rb']
  spec.require_paths = ["lib"]
end
