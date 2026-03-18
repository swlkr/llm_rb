# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "llm"
require "minitest/autorun"
require "webmock/minitest"
require "json"

# Disable all real network connections in tests
WebMock.disable_net_connect!

module TestHelpers
  def setup
    LLM.reset!
    LLM.configure do |c|
      c.openai_api_key = "test-openai-key"
      c.anthropic_api_key = "test-anthropic-key"
      c.gemini_api_key = "test-gemini-key"
    end
  end

  def stub_openai_completion(response_body)
    stub_request(:post, "https://api.openai.com/v1/chat/completions")
      .to_return(status: 200, body: JSON.generate(response_body),
                 headers: { "Content-Type" => "application/json" })
  end

  def stub_anthropic_completion(response_body)
    stub_request(:post, "https://api.anthropic.com/v1/messages")
      .to_return(status: 200, body: JSON.generate(response_body),
                 headers: { "Content-Type" => "application/json" })
  end

  def stub_gemini_completion(model, response_body)
    stub_request(:post, "https://generativelanguage.googleapis.com/v1beta/models/#{model}:generateContent?key=test-gemini-key")
      .to_return(status: 200, body: JSON.generate(response_body),
                 headers: { "Content-Type" => "application/json" })
  end

  def openai_chat_response(content: "Hello!", model: "gpt-4o", tool_calls: nil)
    msg = { "role" => "assistant", "content" => content }
    msg["tool_calls"] = tool_calls if tool_calls
    {
      "id" => "chatcmpl-123",
      "object" => "chat.completion",
      "model" => model,
      "choices" => [{ "index" => 0, "message" => msg, "finish_reason" => "stop" }],
      "usage" => { "prompt_tokens" => 10, "completion_tokens" => 5, "total_tokens" => 15 }
    }
  end

  def anthropic_chat_response(content: "Hello!", model: "claude-sonnet-4-20250514", tool_use: nil)
    blocks = []
    blocks << { "type" => "text", "text" => content } if content
    blocks.concat(tool_use) if tool_use
    {
      "id" => "msg_123",
      "type" => "message",
      "role" => "assistant",
      "model" => model,
      "content" => blocks,
      "usage" => { "input_tokens" => 10, "output_tokens" => 5 }
    }
  end

  def gemini_chat_response(content: "Hello!", model: "gemini-2.5-flash", function_calls: nil)
    parts = []
    parts << { "text" => content } if content
    parts.concat(function_calls) if function_calls
    {
      "candidates" => [{
        "content" => { "parts" => parts, "role" => "model" },
        "finishReason" => "STOP"
      }],
      "usageMetadata" => { "promptTokenCount" => 10, "candidatesTokenCount" => 5 }
    }
  end
end
