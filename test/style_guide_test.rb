require 'minitest/autorun'
require_relative '../lib/aicommit/style_guide'

module Aicommit
  class TestStyleGuide < Minitest::Test
    def test_load_default_guide
      guide = StyleGuide.load('/nonexistent/path')
      assert_includes guide, "Use conventional commits format"
    end

    def test_load_custom_guide
      # Create temporary guide file
      Dir.mktmpdir do |dir|
        guide_path = File.join(dir, '.aicommitrc')
        File.write(guide_path, "Custom guide")
        
        guide = StyleGuide.load(dir)
        assert_equal "Custom guide", guide
      end
    end
  end
end