require 'debug_me'
include DebugMe

require 'optparse'
require 'ruby_llm'
require 'time'

require_relative 'aigcm/version'
require_relative 'aigcm/git_diff'
require_relative 'aigcm/commit_message_generator'
require_relative 'aigcm/style_guide'
require_relative 'aigcm/options'

module Aigcm
  COMMIT_MESSAGE_FILE = '.aigcm_msg'
  RECENT_THRESHOLD = 60 # seconds (1 minute)

  class Error < StandardError; end

  class << self
    attr_reader :parsed_options

    def run(test_mode: false)
      @parsed_options = Options.parse

      dir = Dir.pwd

      if amend?
        system('git commit --amend')
        return
      end

      commit_message = check_recent_commit(dir, dry?)

      # Generate a new commit message if not reusing an existing one
      commit_message ||= generate_commit_message(dir)

      perform_commit(dir, commit_message)

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

    def dry?
      parsed_options[:dry]
    end

    def amend?
      parsed_options[:amend]
    end

    def model
      parsed_options[:model]
    end

    def provider
      parsed_options[:provider]
    end

    private

    def check_recent_commit(dir, dry_run)
      commit_file_path = File.join(dir, COMMIT_MESSAGE_FILE)

      if File.exist?(commit_file_path)
        file_mod_time = File.mtime(commit_file_path)
        current_time = Time.now
        if (current_time - file_mod_time).to_i < RECENT_THRESHOLD
          return nil if dry_run # Skip time check in dry run mode
          return File.read(commit_file_path)
        end
      end

      nil
    end

    def generate_commit_message(dir)
      commit_hash = ARGV.shift # This may be nil
      diff_generator = GitDiff.new(dir: dir, commit_hash: commit_hash, amend: amend?)
      diff = diff_generator.generate_diff

      style_guide = StyleGuide.load(dir, parsed_options[:style])
      generator = CommitMessageGenerator.new(
        model: model,
        provider: provider,
        max_tokens: 1000,
        force_external: parsed_options[:force_external],
        amend: amend?
      )

      commit_message = generator.generate(style_guide, parsed_options[:context])
      File.write(File.join(dir, COMMIT_MESSAGE_FILE), commit_message)
      commit_message
    end

    def perform_commit(dir, commit_message)
      commit_file_path = File.join(dir, COMMIT_MESSAGE_FILE)

      if dry?
        puts "\nDry run - would generate commit message:"
        puts "-"*StyleGuide::LINE_MAX
        puts commit_message
        puts "-"*StyleGuide::LINE_MAX
        puts
      else
        File.write(commit_file_path, commit_message)
        system("git commit --edit -F #{commit_file_path}")
      end
    end
  end
end
