require 'minitest/autorun'
require 'tmpdir'
require 'fileutils'
require_relative '../lib/aigcm/style_guide'

module Aigcm
  class TestStyleGuide < Minitest::Test
    def test_load_default_guide
      # When no COMMITS.md exists, should return default guide
      Dir.mktmpdir do |dir|
        guide = StyleGuide.load(dir)
        assert_includes guide, "Craft a Clear Subject Line"
        assert_includes guide, "#{StyleGuide::LINE_MAX} characters"
        assert_includes guide, "Use Imperative Mood"
      end
    end

    def test_load_custom_guide_from_commits_md
      Dir.mktmpdir do |dir|
        # Create COMMITS.md in the directory
        commits_path = File.join(dir, 'COMMITS.md')
        custom_content = "My custom commit style guide\n- Rule 1\n- Rule 2"
        File.write(commits_path, custom_content)

        guide = StyleGuide.load(dir)
        assert_equal custom_content, guide
      end
    end

    def test_load_custom_guide_from_path
      Dir.mktmpdir do |dir|
        # Create a custom style guide file
        custom_path = File.join(dir, 'my_style.md')
        custom_content = "Custom style from specific path"
        File.write(custom_path, custom_content)

        guide = StyleGuide.load(dir, custom_path)
        assert_equal custom_content, guide
      end
    end

    def test_custom_path_takes_precedence
      Dir.mktmpdir do |dir|
        # Create both COMMITS.md and a custom file
        commits_path = File.join(dir, 'COMMITS.md')
        File.write(commits_path, "From COMMITS.md")

        custom_path = File.join(dir, 'custom.md')
        File.write(custom_path, "From custom path")

        # Custom path should take precedence
        guide = StyleGuide.load(dir, custom_path)
        assert_equal "From custom path", guide
      end
    end

    def test_default_guide_line_max_constant
      assert_equal 72, StyleGuide::LINE_MAX
    end

    def test_nonexistent_directory_returns_default
      guide = StyleGuide.load('/nonexistent/path/that/does/not/exist')
      assert_includes guide, "Craft a Clear Subject Line"
    end
  end
end
