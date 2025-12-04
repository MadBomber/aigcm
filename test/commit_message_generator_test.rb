require 'minitest/autorun'
require 'tempfile'
require 'fileutils'
require_relative '../lib/aigcm/commit_message_generator'

module Aigcm
  class TestCommitMessageGenerator < Minitest::Test
    def setup
      @orig_dir = Dir.pwd
      @temp_dir = Dir.mktmpdir
      Dir.chdir(@temp_dir)
      system('git init', out: File::NULL, err: File::NULL)
      system('git config user.email "test@test.com"', out: File::NULL, err: File::NULL)
      system('git config user.name "Test User"', out: File::NULL, err: File::NULL)

      @generator = CommitMessageGenerator.new(
        model: 'gpt-4o-mini',
        max_tokens: 1000,
        provider: :openai,
        force_external: true
      )
    end

    def teardown
      Dir.chdir(@orig_dir)
      FileUtils.remove_entry @temp_dir if @temp_dir && Dir.exist?(@temp_dir)
    end

    def test_generate_empty_diff
      # GitDiff raises an error when there are no staged changes
      assert_raises(Aigcm::GitDiff::Error) do
        @generator.generate('test style guide')
      end
    end

    def test_generate_with_diff
      File.write('test.txt', 'Hello World')
      system('git add test.txt', out: File::NULL, err: File::NULL)

      result = @generator.generate('Use conventional commits format')
      assert_kind_of String, result
      refute_empty result
      refute_equal "No changes to commit", result
    end

    def test_context_with_file
      Tempfile.create(['context', '.txt']) do |f|
        f.write('Additional context for the commit')
        f.flush

        File.write('feature.rb', 'def hello; puts "hello"; end')
        system('git add feature.rb', out: File::NULL, err: File::NULL)

        result = @generator.generate('Use conventional commits', ["@#{f.path}"])
        assert_kind_of String, result
        refute_empty result
      end
    end

    def test_generate_with_inline_context
      File.write('bugfix.rb', 'fixed_value = 42')
      system('git add bugfix.rb', out: File::NULL, err: File::NULL)

      result = @generator.generate('Use conventional commits', ['This fixes issue #123'])
      assert_kind_of String, result
      refute_empty result
    end
  end
end
