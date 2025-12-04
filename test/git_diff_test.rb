require 'minitest/autorun'
require 'fileutils'
require 'tmpdir'
require_relative '../lib/aigcm/git_diff'

module Aigcm
  class TestGitDiff < Minitest::Test
    def setup
      @orig_dir = Dir.pwd
      @temp_dir = Dir.mktmpdir
      Dir.chdir(@temp_dir)
      setup_git_repo
    end

    def teardown
      Dir.chdir(@orig_dir)
      FileUtils.remove_entry @temp_dir if @temp_dir && Dir.exist?(@temp_dir)
    end

    def test_generate_diff_no_commit_hash
      File.write('test.txt', 'test content')
      system('git add test.txt', out: File::NULL, err: File::NULL)

      diff_generator = GitDiff.new(dir: @temp_dir, commit_hash: nil)
      diff = diff_generator.generate_diff

      assert_kind_of String, diff
      assert_match(/test content/, diff)
    end

    def test_generate_diff_with_amend
      # Create initial commit
      File.write('test.txt', 'initial content')
      system('git add test.txt', out: File::NULL, err: File::NULL)
      system('git commit -m "initial commit"', out: File::NULL, err: File::NULL)

      # Modify and stage for amend
      File.write('test.txt', 'updated content')
      system('git add test.txt', out: File::NULL, err: File::NULL)

      diff_generator = GitDiff.new(dir: @temp_dir, commit_hash: nil, amend: true)
      diff = diff_generator.generate_diff

      assert_kind_of String, diff
      assert_match(/updated content/, diff)
    end

    def test_invalid_directory
      Dir.chdir(@orig_dir)
      assert_raises(GitDiff::Error) do
        GitDiff.new(dir: '/nonexistent_directory_that_does_not_exist', commit_hash: nil)
      end
    end

    def test_not_a_git_repo
      non_git_dir = Dir.mktmpdir
      begin
        assert_raises(GitDiff::Error) do
          GitDiff.new(dir: non_git_dir, commit_hash: nil)
        end
      ensure
        FileUtils.remove_entry non_git_dir
      end
    end

    def test_no_changes_raises_error
      diff_generator = GitDiff.new(dir: @temp_dir, commit_hash: nil)
      assert_raises(GitDiff::Error) do
        diff_generator.generate_diff
      end
    end

    private

    def setup_git_repo
      system('git init', out: File::NULL, err: File::NULL)
      system('git config user.email "test@example.com"', out: File::NULL, err: File::NULL)
      system('git config user.name "Test User"', out: File::NULL, err: File::NULL)
    end
  end
end
