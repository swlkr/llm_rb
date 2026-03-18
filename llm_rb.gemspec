# frozen_string_literal: true

require_relative "lib/llm/version"

Gem::Specification.new do |spec|
  spec.name = "llm_rb"
  spec.version = LLM::VERSION
  spec.authors = ["Sean"]
  spec.summary = "A zero-dependency Ruby gem for LLM chat completions, tool use, and image generation"
  spec.description = "Unified API for Anthropic, Google Gemini, and OpenAI-compatible APIs. " \
                     "Supports chat completions, tool use, structured output, streaming, and image generation. " \
                     "No runtime dependencies — only Ruby stdlib."
  spec.homepage = "https://github.com/getletterpress/llm_rb"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1"

  spec.files = Dir["lib/**/*.rb", "llm_rb.gemspec", "README.md"]
  spec.require_paths = ["lib"]

  spec.add_dependency "base64"
  spec.add_dependency "logger"

  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "webmock", "~> 3.0"
end
