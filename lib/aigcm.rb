require 'debug_me'
include DebugMe

require 'optparse'
require 'ai_client'
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
    def run(test_mode: false)
      dir = Dir.pwd
      options = Options.parse

      if options[:amend]
        system('git commit --amend')
        return
      end

      commit_message = check_recent_commit(dir, options[:dry])

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

    private

    def check_recent_commit(dir, dry)
      commit_file_path = File.join(dir, COMMIT_MESSAGE_FILE)

      if File.exist?(commit_file_path)
        file_mod_time = File.mtime(commit_file_path)
        current_time = Time.now
        if (current_time - file_mod_time).to_i < RECENT_THRESHOLD
          return nil if dry # Skip time check in dry run mode
          return File.read(commit_file_path)
        end
      end

      nil
    end

    def generate_commit_message(dir, options)
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

    def perform_commit(dir, commit_message, options)
      commit_file_path = File.join(dir, COMMIT_MESSAGE_FILE)

      if options[:dry]
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
