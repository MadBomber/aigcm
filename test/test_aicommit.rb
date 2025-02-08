# frozen_string_literal: true

require "test_helper"

class TestAicommit < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Aicommit::VERSION
  end

  def test_it_does_something_useful
    assert_respond_to ::Aicommit, :run
  end
end
