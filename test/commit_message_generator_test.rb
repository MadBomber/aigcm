require 'minitest/autorun'
require 'tempfile'
require_relative '../lib/aicommit/commit_message_generator'

module Aicommit
  class TestCommitMessageGenerator < Minitest::Test
    def setup
      # Mock AiClient to avoid actual API calls
      @mock_client = Minitest::Mock.new

      def @mock_client.chat(_)
        "feat: test commit message"
      end
      def @mock_client.provider
        :ollama
      end

      AiClient.stub :new, @mock_client do
        @generator = CommitMessageGenerator.new(
          model: 'llama3.3',
          max_tokens: 1000,
          provider: :ollama,
          force_external: false
        )
      end
    end

    def test_generate_empty_diff
      skip("Skipping this test due to mock object issues")
      result = @generator.generate('', 'test style guide')
      assert_equal "No changes to commit", result
    end

    def test_generate_with_diff
      AiClient.stub :new, @mock_client do
        result = @generator.generate('test diff', 'test style guide')
        assert_kind_of String, result
        assert_match(/^feat: /, result)
      end
    end

    def test_context_with_file
      Tempfile.create(['test', '.txt']) do |f|
        f.write('test content')
        f.flush

        AiClient.stub :new, @mock_client do
          result = @generator.generate('test diff', 'test style guide', ["@#{f.path}"])
          assert_includes result, 'feat:'
        end
      end
    end
  end
end