# frozen_string_literal: true

require "test_helper"

class ConfigurationTest < Minitest::Test
  def test_defaults
    config = LLM::Configuration.new
    assert_nil config.openai_api_key
    assert_equal "https://api.openai.com", config.openai_api_base
    assert_nil config.anthropic_api_key
    assert_equal "https://api.anthropic.com", config.anthropic_api_base
    assert_nil config.gemini_api_key
    assert_equal "https://generativelanguage.googleapis.com", config.gemini_api_base
    assert_equal 120, config.request_timeout
    assert_equal 3, config.max_retries
    assert_nil config.http_proxy
  end

  def test_custom_values
    config = LLM::Configuration.new
    config.openai_api_key = "sk-test"
    config.request_timeout = 60
    assert_equal "sk-test", config.openai_api_key
    assert_equal 60, config.request_timeout
  end
end
