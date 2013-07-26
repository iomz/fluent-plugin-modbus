# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)

Gem::Specification.new do |gem|
  gem.name          = "fluent-plugin-modbus"
  gem.version       = "0.1.0"
  gem.authors       = ["iomz"]
  gem.email         = ["iomz@sfc.wide.ad.jp"]
  gem.description   = %q{Retrieve register value from modbus and store in MySQL}
  gem.summary       = %q{fluent-plugin}
  gem.homepage      = "https://github.com/iomz/fluent-plugin-modbus"

  gem.rubyforge_project = "fluent-plugin_modbus"
  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

=begin
  gem.add_development_dependency = "eventmachine"
  gem.add_runtime_dependency = "fluentd"
  gem.add_runtime_dependency = "rmodbus"
  gem.add_runtime_dependency = "serialport"
  gem.add_runtime_dependency = "mysql2-cs-bind"
=end
end
