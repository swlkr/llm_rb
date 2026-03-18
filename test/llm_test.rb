# frozen_string_literal: true

require "test_helper"

class LLMTest < Minitest::Test
  include TestHelpers

  def test_version
    refute_nil LLM::VERSION
  end

  def test_configure
    LLM.configure do |c|
      c.openai_api_key = "my-key"
    end
    assert_equal "my-key", LLM.config.openai_api_key
  end

  def test_chat_returns_chat_instance
    stub_openai_completion(openai_chat_response)
    chat = LLM.chat(model: "gpt-4o")
    assert_instance_of LLM::Chat, chat
  end

  def test_provider_resolution_openai
    chat = LLM.chat(model: "gpt-4o")
    assert_instance_of LLM::Providers::OpenAI, chat.provider
  end

  def test_provider_resolution_anthropic
    chat = LLM.chat(model: "claude-sonnet-4-20250514")
    assert_instance_of LLM::Providers::Anthropic, chat.provider
  end

  def test_provider_resolution_gemini
    chat = LLM.chat(model: "gemini-2.5-flash")
    assert_instance_of LLM::Providers::Gemini, chat.provider
  end

  def test_explicit_provider
    chat = LLM.chat(model: "my-local-model", provider: :openai)
    assert_instance_of LLM::Providers::OpenAI, chat.provider
  end

  def test_reset
    LLM.configure { |c| c.openai_api_key = "key1" }
    LLM.reset!
    assert_nil LLM.config.openai_api_key
  end
end
