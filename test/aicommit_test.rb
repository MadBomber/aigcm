# frozen_string_literal: true

require "test_helper"
require 'fileutils'

class TestAicommit < Minitest::Test
  def setup
    @test_message = 'feat: example commit message'
    @orig_dir = Dir.pwd
    @temp_dir = Dir.mktmpdir
    Dir.chdir(@temp_dir)
  end

  def teardown
    Dir.chdir(@orig_dir)
    FileUtils.remove_entry @temp_dir if @temp_dir && Dir.exist?(@temp_dir)
  end

  def test_that_it_has_a_version_number
    refute_nil ::Aicommit::VERSION
  end

  def test_it_does_something_useful
    assert_respond_to ::Aicommit, :run
  end

  def test_run_with_invalid_provider
    ARGV.replace(['--provider=invalid'])
    assert_output(/Invalid provider specified/) do
      assert_raises(SystemExit) { Aicommit.run(test_mode: true) }
    end
  end

  def test_run_without_api_key
    ARGV.replace([])
    ENV.delete('OPENAI_API_KEY')
    assert_output(/Error: OpenAI API key is required/) do
      assert_raises(SystemExit) { Aicommit.run(test_mode: true) }
    end
  end

  def test_run_dry_mode
    ARGV.replace(['--dry'])
    AiClient.stub :new, Minitest::Mock.new do |mock|
      mock.expect(:chat, @test_message) { |_msg| }
      mock.expect(:provider, :ollama)
      output = capture_io { Aicommit.run(test_mode: true) }[0]
      assert_match(/Dry run - would generate commit message:/, output)
      # Check that no file was written and no commit was performed
      refute File.exist?(File.join(@temp_dir, '.aicommit_msg'))
    end
  end

  def test_run_with_commit_message_written
    ARGV.replace([])
    AiClient.stub :new, Minitest::Mock.new do |mock|
      mock.expect(:chat, @test_message) { |_msg| }
      mock.expect(:provider, :ollama)
      Aicommit.run(test_mode: true)
      commit_msg_path = File.join(@temp_dir, '.aicommit_msg')
      assert File.exist?(commit_msg_path)
      assert_equal @test_message, File.read(commit_msg_path)
      # Assuming a real system call isn't tested here
    end
  end
end
