# frozen_string_literal: true

require_relative "lib/net/http/version"

Gem::Specification.new do |spec|
  spec.name          = "net-http-ext"
  spec.version       = NetHTTPExt::VERSION
  spec.authors       = ["Grant Birkinbine"]
  spec.email         = "grant.birkinbine@gmail.com"
  spec.license       = "MIT"

  spec.summary       = "Ruby Net::HTTP extended with sensible defaults"
  spec.description   = <<~SPEC_DESC
    Safe defaults, persistent connections, thread safety, and basic logging for Ruby's Net::HTTP library
  SPEC_DESC

  spec.homepage = "https://github.com/grantbirki/net-http-ext"
  spec.metadata = {
    "source_code_uri" => "https://github.com/grantbirki/net-http-ext",
    "documentation_uri" => "https://github.com/grantbirki/net-http-ext",
    "bug_tracker_uri" => "https://github.com/grantbirki/net-http-ext/issues"
  }

  spec.add_dependency "timeout", "~> 0.4.3"
  spec.add_dependency "json", "~> 2.10", ">= 2.10.2"
  spec.add_dependency "uri", "~> 1.0", ">= 1.0.3"
  spec.add_dependency "logger", "~> 1"
  spec.add_dependency "net-http-persistent", "~> 4.0", ">= 4.0.5"

  # https://github.com/drbrain/net-http-persistent/blob/234f3b2c6a0ed044e3c55e3de982257b4860ba0a/net-http-persistent.gemspec#L17C29-L17C37
  spec.required_ruby_version = ">= 2.4"

  spec.files = %w[LICENSE README.md net-http-ext.gemspec]
  spec.files += Dir.glob("lib/**/*.rb")
  spec.require_paths = ["lib"]
end
