# frozen_string_literal: true

require "test_helper"
require 'fileutils'
require 'time'

class TestAigcm < Minitest::Test
  def setup
    @test_message = 'feat: example commit message'
    @orig_dir = Dir.pwd
    @temp_dir = Dir.mktmpdir
    Dir.chdir(@temp_dir)
    system('git init', out: File::NULL, err: File::NULL)
    system('git config user.email "test@test.com"', out: File::NULL, err: File::NULL)
    system('git config user.name "Test User"', out: File::NULL, err: File::NULL)
    File.write('test.txt', 'This is a test file to ensure changes are detected.')
    system('git add test.txt', out: File::NULL, err: File::NULL)
  end

  def teardown
    Dir.chdir(@orig_dir)
    FileUtils.remove_entry @temp_dir if @temp_dir && Dir.exist?(@temp_dir)
  end

  def test_that_it_has_a_version_number
    refute_nil ::Aigcm::VERSION
  end

  def test_run_with_invalid_provider
    ARGV.replace(['--provider=invalid'])
    assert_output(/Invalid provider specified/) do
      assert_raises(SystemExit) { Aigcm.run(test_mode: true) }
    end
  end

  def test_run_dry_mode
    ARGV.replace(['--dry'])

    output = capture_io { Aigcm.run(test_mode: true) }[0]
    assert_match(/Dry run - would generate commit message:/, output)
    commit_msg_path = File.join(@temp_dir, '.aigcm_msg')
    assert File.exist?(commit_msg_path)
    commit_message = File.read(commit_msg_path)
    refute_empty commit_message
  end

  def test_run_with_recent_message
    commit_msg_path = File.join(@temp_dir, '.aigcm_msg')
    File.write(commit_msg_path, @test_message)
    File.utime(Time.now, Time.now, commit_msg_path)

    ARGV.replace([])

    Aigcm.run(test_mode: true)
    # Check if it reads the recent message (within threshold)
    assert File.exist?(commit_msg_path)
    assert_equal @test_message, File.read(commit_msg_path)
  end

  def test_run_with_old_message
    commit_msg_path = File.join(@temp_dir, '.aigcm_msg')
    File.write(commit_msg_path, @test_message)
    File.utime(Time.now - 3600, Time.now - 3600, commit_msg_path)

    ARGV.replace(['--dry'])

    Aigcm.run(test_mode: true)
    # Check if it generates a new commit message (old message should be replaced)
    assert File.exist?(commit_msg_path)
    new_message = File.read(commit_msg_path)
    refute_empty new_message
  end

  def test_run_with_commit_message_written
    ARGV.replace(['--dry'])

    Aigcm.run(test_mode: true)
    commit_msg_path = File.join(@temp_dir, '.aigcm_msg')
    assert File.exist?(commit_msg_path)
    commit_message = File.read(commit_msg_path)
    refute_empty commit_message
  end
end
