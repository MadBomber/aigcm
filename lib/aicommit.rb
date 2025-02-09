# lib/aicommit.rb

#
# TODO:   gh repo view --json isPrivate -q '.isPrivate'
#

require 'debug_me'
include DebugMe


require 'optparse'
require 'ai_client'

require_relative 'aicommit/version'
require_relative 'aicommit/git_diff'
require_relative 'aicommit/commit_message_generator'
require_relative 'aicommit/style_guide'

module Aicommit
  COMMIT_MESSAGE_FILE = '.aicommit_msg'

  class Error < StandardError; end

  def self.run(test_mode: false)
    options = {
      amend: false,
      context: [],
      dry: false,
      model: 'gpt-4o-mini',
      provider: nil,
      force_external: false,
      style: nil
    }

    begin
      OptionParser.new do |opts|
        opts.banner = "Usage: aicommit [options] [ref]"

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

        opts.on("-sSTYLE", "--style=STYLE", "Path to the style guide file") do |style|
          options[:style] = style
        end

        opts.on("--default", "Print the default style guide and exit") do
          puts "\nDefault Style Guide:"
          puts "-------------------"
          puts StyleGuide::DEFAULT_GUIDE
          exit
        end

        opts.on("--version", "Show version") do
          puts Aicommit::VERSION
          exit
        end
      end.parse!
    rescue OptionParser::InvalidOption => e
      STDERR.puts "Error: '#{e.message}'"
      exit 1
    end

    # unless test_mode
    #   unless options[:api_key]
    #     puts "Error: OpenAI API key is required. Set OPENAI_API_KEY environment variable or use --openai-key"
    #     exit 1
    #   end
    # end

    dir = Dir.pwd
    commit_message = nil
    diff = nil
    begin
      if options[:amend]
        system('git commit --amend')
        return
      end

      diff_generator = GitDiff.new(dir: dir, commit_hash: ARGV.shift, amend: options[:amend])
      diff = diff_generator.generate_diff

      style_guide = StyleGuide.load(dir, options[:style])
      generator = CommitMessageGenerator.new(
        model: options[:model],
        provider: options[:provider],
        max_tokens: 1000,
        force_external: options[:force_external]
      )

      commit_message = generator.generate(diff, style_guide, options[:context])
      if options[:dry]
        puts "\nDry run - would generate commit message:"
        puts "-"*72
        puts commit_message
        puts "-"*72
        puts
        File.write(File.join(dir, Aicommit::COMMIT_MESSAGE_FILE), commit_message)
        return commit_message
      else
        File.write(File.join(dir, Aicommit::COMMIT_MESSAGE_FILE), commit_message)
        system("git commit --edit -F #{Aicommit::COMMIT_MESSAGE_FILE}")
      end
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
