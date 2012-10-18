# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)

Gem::Specification.new do |gem|
  gem.name          = "fluent-plugin-modbus"
  gem.version       = "0.0.1"
  gem.authors       = [" MIZUTANI Iori"]
  gem.email         = ["iomz@sfc.wide.ad.jp"]
  gem.description   = %q{Input plugin for modbus}
  gem.summary       = %q{Input plugin for modbus}
  gem.homepage      = "https://github.com/iomz/fluent-plugin-modbus"

  gem.rubyforge_project = "fluent-plugin_modbus"
  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  # gem.add_development_dependency = "fluentd"
  # gem.add_runtime_dependency = "fluentd"
end
