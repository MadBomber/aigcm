# frozen_string_literal: true

require "test_helper"

class TestOptions < Minitest::Test
  def setup
    @original_argv = ARGV.dup
  end

  def teardown
    ARGV.replace(@original_argv)
  end

  def test_parse_valid_options
    ARGV.replace(['--amend'])
    options = Aigcm::Options.parse
    assert_equal true, options[:amend]
  end

  def test_parse_context_option
    context_value = "test context"
    ARGV.replace(["--context=#{context_value}"])
    options = Aigcm::Options.parse
    assert_includes options[:context], context_value
  end

  def test_invalid_provider_option
    ARGV.replace(['--provider=invalid'])
    assert_output(/Invalid provider specified/) do
      assert_raises(SystemExit) { Aigcm::Options.parse }
    end
  end

  def test_default_options
    ARGV.replace([])
    options = Aigcm::Options.parse
    assert_equal false, options[:amend]
    assert_equal [], options[:context]
    assert_equal false, options[:dry]
    assert_equal 'gpt-4o-mini', options[:model]
    assert_nil options[:provider]
    assert_equal false, options[:force_external]
    assert_nil options[:style]
  end
end
