# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "itsdangerous"
  spec.version       = '0.1'
  spec.authors       = ["Marcus McCurdy"]
  spec.email         = ["marcus.mccurdy@gmail.com"]
  spec.summary       = %q{itsdangerous ported to Ruby}
  spec.description   = %q{Longer description of your project.}
  spec.homepage      = "http://github.com/volker48/itsdangerousr/"
  spec.license       = "MIT"

  spec.files         = ['lib/NAME.rb']
  spec.executables   = ['bin/NAME']
  spec.test_files    = ['tests/NAME_tests.rb']
  spec.require_paths = ["lib"]
end
