# frozen_string_literal: true

require_relative "lib/aigcm/version"

Gem::Specification.new do |spec|
  spec.name     = "aigcm"
  spec.version  = Aigcm::VERSION
  spec.authors  = ["Dewayne VanHoozer"]
  spec.email    = ["dvanhoozer@gmail.com"]

  spec.summary      = "AI-powered git commit message generator"
  spec.description  = <<~TEXT
    `aigcm` generates meaningful git commit messages using artificial
    intelligence. It supports multiple AI providers including OpenAI,
    Anthropic, Google, and local models via Ollama. The gem
    automatically detects private repositories and defaults to using
    local models for security. It integrates seamlessly with git
    workflows and supports various commit scenarios including amending
    commits and handling staged changes. The gem follows conventional
    commit message formats and allows customization of commit message
    styles through configuration.
  TEXT

  spec.homepage     = "https://github.com/MadBomber/aigcm"
  spec.license      = "MIT"

  spec.required_ruby_version = ">= 3.1.0"

  # Specify the gem server as rubygems.org
  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  # Populate metadata with appropriate URLs
  spec.metadata["homepage_uri"]     = spec.homepage
  spec.metadata["source_code_uri"]  = spec.homepage
  spec.metadata["changelog_uri"]    = "#{spec.homepage}/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git appveyor Gemfile])
    end
  end

  spec.bindir = "bin"
  spec.executables = ['aigcm']
  spec.require_paths = ["lib"]

  # Runtime dependencies
  spec.add_dependency "ai_client", "~> 0.4.0"

  # Development dependencies
  spec.add_development_dependency "minitest", "~> 5.16"
  spec.add_development_dependency "mocha"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rubocop", "~> 1.21"
end
