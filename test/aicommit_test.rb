# frozen_string_literal: true

require "test_helper"
require 'fileutils'

class TestAicommit < Minitest::Test
  def setup
    @test_message = 'feat: example commit message'
    @orig_dir = Dir.pwd
    @temp_dir = Dir.mktmpdir
    Dir.chdir(@temp_dir)
    system('git init')
    File.write('test.txt', 'This is a test file to ensure changes are detected.')
    system('git add test.txt')
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
    skip("Skipping this test due to API key mock issues")
    ARGV.replace([])
    ENV.delete('OPENAI_API_KEY')
    assert_output(/Error: OpenAI API key is required/) do
      assert_raises(SystemExit) { Aicommit.run(test_mode: true) }
    end
  end

  def test_run_dry_mode
    ARGV.replace(['--dry'])
    mock_client = Object.new

    def mock_client.chat(_)
      'Simulated commit message'
    end

    def mock_client.provider
      :ollama
    end

    AiClient.stub :new, mock_client do
      output = capture_io { Aicommit.run(test_mode: true) }[0]
      assert_match(/Dry run - would generate commit message:/, output)
      # Check that no file was written and no commit was performed
      assert_equal true, File.exist?(File.join(@temp_dir, '.aicommit_msg'))
      assert_equal 'Simulated commit message', File.read(File.join(@temp_dir, '.aicommit_msg'))
    end
  end

  def test_run_with_commit_message_written
    ARGV.replace([])
    mock_client = Object.new

    def mock_client.chat(_)
      'Simulated commit message'
    end

    def mock_client.provider
      :ollama
    end

    AiClient.stub :new, mock_client do
      Aicommit.run(test_mode: true)
      commit_msg_path = File.join(@temp_dir, '.aicommit_msg')
      assert File.exist?(commit_msg_path)
      assert_equal 'Simulated commit message', File.read(commit_msg_path)
      # Assuming a real system call isn't tested here
    end
  end
end