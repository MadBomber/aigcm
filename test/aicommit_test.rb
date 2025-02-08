# frozen_string_literal: true

require "test_helper"

class TestAicommit < Minitest::Test
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
      mock.expect(:chat, 'feat: example') { |_msg| }
      mock.expect(:provider, :ollama)
      Aicommit.run(test_mode: true)
    end
    assert_match(/Dry run - would generate commit message:/, $stdout.string)
  end
end
