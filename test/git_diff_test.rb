require 'minitest/autorun'
require 'fileutils'
require 'tmpdir'
require_relative '../lib/aicommit/git_diff'

module Aicommit
  class TestGitDiff < Minitest::Test
    def setup
      @temp_dir = Dir.mktmpdir
      setup_git_repo
      @diff_generator = GitDiff.new(dir: @temp_dir, commit_hash: nil, amend: false)
    end

    def teardown
      FileUtils.remove_entry @temp_dir if @temp_dir && Dir.exist?(@temp_dir)
    end

    def test_generate_diff_no_commit_hash
      create_test_file("test.txt", "test content")
      system("cd #{@temp_dir} && git add test.txt")
      diff = @diff_generator.generate_diff
      assert_kind_of String, diff
      assert_match(/test content/, diff)
    end

    def test_generate_diff_with_amend
      create_test_file("test.txt", "test content")
      system("cd #{@temp_dir} && git add test.txt && git commit -m 'test commit'")
      create_test_file("test.txt", "updated content")
      system("cd #{@temp_dir} && git add test.txt")
      
      diff_generator = GitDiff.new(dir: @temp_dir, commit_hash: nil, amend: true)
      diff = diff_generator.generate_diff
      assert_kind_of String, diff
    end

    def test_invalid_directory
      assert_raises(GitDiff::Error) do
        GitDiff.new(dir: '/nonexistent', commit_hash: nil, amend: false)
      end
    end

    private

    def setup_git_repo
      system(<<~SHELL)
        cd #{@temp_dir} && \
        git init && \
        git config user.email "test@example.com" && \
        git config user.name "Test User"
      SHELL
    end

    def create_test_file(name, content)
      File.write(File.join(@temp_dir, name), content)
    end
  end
end