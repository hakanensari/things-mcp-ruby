# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name = "things-mcp"
  spec.version = "0.1.0"
  spec.authors = ["Hakan Ensari"]
  spec.email = ["hakanensari@gmail.com"]

  spec.summary = "MCP server for Things 3"
  spec.description = "A Model Context Protocol (MCP) server for Things 3, implemented in Ruby"
  spec.homepage = "https://github.com/hakanensari/things-mcp-ruby"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.files = Dir.glob("{bin,lib}/**/*") + ["README.md", "LICENSE", "Gemfile", "Rakefile"]
  spec.bindir = "bin"
  spec.executables = ["things_mcp_server"]
  spec.require_paths = ["lib"]

  spec.add_dependency("logger", "~> 1.4")
  spec.add_dependency("mcp", "~> 0.1")
  spec.add_dependency("sqlite3", "~> 2.0")
end
