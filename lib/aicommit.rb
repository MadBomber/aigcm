# lib/aicommit.rb

#
# TODO:   gh repo view --json isPrivate -q '.isPrivate'
#

require 'optparse'
require 'ai_client'

require_relative 'aicommit/version'
require_relative 'aicommit/git_diff'
require_relative 'aicommit/commit_message_generator'
require_relative 'aicommit/style_guide'

module Aicommit
  class Error < StandardError; end

  def self.run(test_mode: false)
    options = {
      amend: false,
      context: [],
      dry: false,
      model: 'gpt-4o',  # Default to GPT-4o as the new model
      provider: :ollama, # Default to ollama for local execution
      api_key: ENV['OPENAI_API_KEY'],
      save_key: false,
      force_external: false
    }

    OptionParser.new do |opts|
      opts.banner = "Usage: aicommit-rb [options] [ref]"

      opts.on("-a", "--amend", "Amend the last commit") do
        options[:amend] = true
      end

      opts.on("-cCONTEXT", "--context=CONTEXT", "Extra context beyond the diff") do |context|
        options[:context] << context
      end

      opts.on("-d", "--dry", "Dry run the command") do
        options[:dry] = true
      end

      opts.on("-mMODEL", "--model=MODEL", "The model to use") do |model|
        options[:model] = model
      end

      opts.on("--provider=PROVIDER", "Specify the provider (ollama, openai, anthropic, etc)") do |provider|
        provider = provider.to_sym
        unless [:ollama, :openai, :anthropic, :google, :mistral].include?(provider)
          puts "Invalid provider specified. Valid providers are: ollama, openai, anthropic, google, mistral"
          exit 1
        end
        options[:provider] = provider
      end

      opts.on("--force-external", "Force using external AI provider even for private repos") do
        options[:force_external] = true
      end

      opts.on("--version", "Show version") do
        puts "aicommit-rb version #{Aicommit::VERSION}"
        exit
      end
    end.parse!

    unless test_mode
      unless options[:api_key]
        puts "Error: OpenAI API key is required. Set OPENAI_API_KEY environment variable or use --openai-key"
        exit 1
      end
    end

    # Generate diff and commit message
    dir = Dir.pwd
    begin
      diff_generator = GitDiff.new(dir: dir, commit_hash: ARGV.shift, amend: options[:amend])
      diff = diff_generator.generate_diff

      style_guide = StyleGuide.load(dir)
      generator = CommitMessageGenerator.new(
        api_key: options[:api_key],
        model: options[:model],
        max_tokens: 1000,
        force_external: options[:force_external]
      )

      commit_message = generator.generate(diff, style_guide, options[:context])
      return commit_message unless options[:dry]
      
      puts "Dry run - would generate commit message:\n#{commit_message}"
      nil
    rescue GitDiff::Error => e
      puts "Git error: #{e.message}"
      exit 1
    rescue StandardError => e
      puts "Error: #{e.message}"
      exit 1
    end
  end
end
