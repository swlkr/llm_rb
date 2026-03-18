# frozen_string_literal: true

require "test_helper"

class AnthropicProviderTest < Minitest::Test
  include TestHelpers

  def test_basic_chat
    stub_anthropic_completion(anthropic_chat_response(content: "Hi there!"))
    chat = LLM.chat(model: "claude-sonnet-4-20250514")
    response = chat.ask("Hello")
    assert_equal "Hi there!", response.content.to_s
    assert response.assistant?
  end

  def test_system_message_extracted
    stub_anthropic_completion(anthropic_chat_response(content: "I'm helpful"))
    chat = LLM.chat(model: "claude-sonnet-4-20250514")
    chat.with_instructions("You are helpful").ask("Hi")

    assert_requested(:post, "https://api.anthropic.com/v1/messages") { |req|
      body = JSON.parse(req.body)
      body["system"] == "You are helpful" &&
        body["messages"].none? { |m| m["role"] == "system" }
    }
  end

  def test_max_tokens_included
    stub_anthropic_completion(anthropic_chat_response)
    chat = LLM.chat(model: "claude-sonnet-4-20250514")
    chat.ask("Hi")

    assert_requested(:post, "https://api.anthropic.com/v1/messages") { |req|
      JSON.parse(req.body)["max_tokens"] == 4096
    }
  end

  def test_headers
    stub_anthropic_completion(anthropic_chat_response)
    chat = LLM.chat(model: "claude-sonnet-4-20250514")
    chat.ask("Hi")

    assert_requested(:post, "https://api.anthropic.com/v1/messages",
                     headers: { "x-api-key" => "test-anthropic-key", "anthropic-version" => "2023-06-01" })
  end

  def test_tool_use
    tool_response = anthropic_chat_response(
      content: nil,
      tool_use: [{
        "type" => "tool_use",
        "id" => "toolu_123",
        "name" => "test_calculator",
        "input" => { "expression" => "2+2" }
      }]
    )
    final_response = anthropic_chat_response(content: "The answer is 4")

    stub_request(:post, "https://api.anthropic.com/v1/messages")
      .to_return(
        { status: 200, body: JSON.generate(tool_response), headers: { "Content-Type" => "application/json" } },
        { status: 200, body: JSON.generate(final_response), headers: { "Content-Type" => "application/json" } }
      )

    chat = LLM.chat(model: "claude-sonnet-4-20250514")
    response = chat.with_tools(TestCalculator).ask("What is 2+2?")
    assert_equal "The answer is 4", response.content.to_s
  end

  def test_structured_output_via_tool_use
    tool_response = anthropic_chat_response(
      content: nil,
      tool_use: [{
        "type" => "tool_use",
        "id" => "toolu_123",
        "name" => "Person",
        "input" => { "name" => "John", "age" => 30 }
      }]
    )
    stub_anthropic_completion(tool_response)

    chat = LLM.chat(model: "claude-sonnet-4-20250514")
    response = chat.with_schema(
      name: "Person",
      schema: { type: "object", properties: { name: { type: "string" }, age: { type: "integer" } } }
    ).ask("Extract: John is 30")

    parsed = JSON.parse(response.content.to_s)
    assert_equal "John", parsed["name"]
    assert_equal 30, parsed["age"]
  end
end
