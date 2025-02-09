# lib/aicommit.rb

require 'debug_me'
include DebugMe

require 'optparse'
require 'ai_client'
require 'time'

require_relative 'aicommit/version'
require_relative 'aicommit/git_diff'
require_relative 'aicommit/commit_message_generator'
require_relative 'aicommit/style_guide'

module Aicommit
  COMMIT_MESSAGE_FILE = '.aicommit_msg'
  RECENT_THRESHOLD = 60 # seconds (1 minute)

  class Error < StandardError; end

  def self.run(test_mode: false)
    dir = Dir.pwd
    options = parse_options

    if options[:amend]
      system('git commit --amend')
      return
    end

    commit_message = check_recent_commit(dir)

    # Generate a new commit message if not reusing an existing one
    commit_message ||= generate_commit_message(dir, options)

    perform_commit(dir, commit_message, options)

  rescue OptionParser::InvalidOption => e
    STDERR.puts "Error: '#{e.message}'"
    exit 1
  rescue GitDiff::Error => e
    puts "Git error: #{e.message}"
    exit 1
  rescue StandardError => e
    puts "Error: #{e.message}"
    exit 1
  end

  private_class_method def self.parse_options
    options = {
      amend: false,
      context: [],
      dry: false,
      model: 'gpt-4o-mini',
      provider: nil,
      force_external: false,
      style: nil
    }

    OptionParser.new do |opts|
      opts.banner = "Usage: aicommit [options] [ref]"

      opts.on("-a", "--amend", "Amend the last commit") { options[:amend] = true }

      opts.on("-cCONTEXT", "--context=CONTEXT", "Extra context beyond the diff") do |context|
        options[:context] << context
      end

      opts.on("-d", "--dry", "Dry run the command") { options[:dry] = true }

      opts.on("-mMODEL", "--model=MODEL", "The model to use") { |model| options[:model] = model }

      opts.on("--provider=PROVIDER", "Specify the provider (ollama, openai, anthropic, etc)") do |provider|
        provider = provider.to_sym
        unless [:ollama, :openai, :anthropic, :google, :mistral].include?(provider)
          puts "Invalid provider specified. Valid providers are: ollama, openai, anthropic, google, mistral"
          exit 1
        end
        options[:provider] = provider
      end

      opts.on("--force-external", "Force using external AI provider even for private repos") {
        options[:force_external] = true
      }

      opts.on("-sSTYLE", "--style=STYLE", "Path to the style guide file") { |style| options[:style] = style }

      opts.on("--default", "Print the default style guide and exit") do
        puts "\nDefault Style Guide:"
        puts "-------------------"
        puts StyleGuide::DEFAULT_GUIDE
        exit
      end

      opts.on("--version", "Show version") { puts Aicommit::VERSION; exit }

    end.parse!

    options
  end

  private_class_method def self.check_recent_commit(dir)
    commit_file_path = File.join(dir, COMMIT_MESSAGE_FILE)

    if File.exist?(commit_file_path)
      file_mod_time = File.mtime(commit_file_path)
      current_time = Time.now
      if (current_time - file_mod_time).to_i < RECENT_THRESHOLD
        return File.read(commit_file_path)
      end
    end

    nil
  end

  private_class_method def self.generate_commit_message(dir, options)
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
    File.write(File.join(dir, COMMIT_MESSAGE_FILE), commit_message)
    commit_message
  end

  private_class_method def self.perform_commit(dir, commit_message, options)
    commit_file_path = File.join(dir, COMMIT_MESSAGE_FILE)

    if options[:dry]
      puts "\nDry run - would generate commit message:"
      puts "-"*72
      puts commit_message
      puts "-"*72
      puts
    else
      File.write(commit_file_path, commit_message)
      system("git commit --edit -F #{commit_file_path}")
    end
  end
end
