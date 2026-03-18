# frozen_string_literal: true

require "test_helper"

class GeminiProviderTest < Minitest::Test
  include TestHelpers

  GEMINI_URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=test-gemini-key"

  def test_basic_chat
    stub_gemini_completion("gemini-2.5-flash", gemini_chat_response(content: "Hi there!"))
    chat = LLM.chat(model: "gemini-2.5-flash")
    response = chat.ask("Hello")
    assert_equal "Hi there!", response.content.to_s
    assert response.assistant?
  end

  def test_api_key_in_url
    stub_gemini_completion("gemini-2.5-flash", gemini_chat_response)
    chat = LLM.chat(model: "gemini-2.5-flash")
    chat.ask("Hi")
    assert_requested(:post, GEMINI_URL)
  end

  def test_system_instruction
    stub_gemini_completion("gemini-2.5-flash", gemini_chat_response)
    chat = LLM.chat(model: "gemini-2.5-flash")
    chat.with_instructions("You are helpful").ask("Hi")

    assert_requested(:post, GEMINI_URL) { |req|
      body = JSON.parse(req.body)
      body["systemInstruction"] == { "parts" => [{ "text" => "You are helpful" }] }
    }
  end

  def test_role_mapping
    stub_gemini_completion("gemini-2.5-flash", gemini_chat_response)
    chat = LLM.chat(model: "gemini-2.5-flash")
    chat.ask("Hi")

    assert_requested(:post, GEMINI_URL) { |req|
      body = JSON.parse(req.body)
      body["contents"].any? { |c| c["role"] == "user" }
    }
  end

  def test_tool_use
    tool_response = gemini_chat_response(
      content: nil,
      function_calls: [{
        "functionCall" => {
          "name" => "test_calculator",
          "args" => { "expression" => "2+2" }
        }
      }]
    )
    final_response = gemini_chat_response(content: "The answer is 4")

    stub_request(:post, GEMINI_URL)
      .to_return(
        { status: 200, body: JSON.generate(tool_response), headers: { "Content-Type" => "application/json" } },
        { status: 200, body: JSON.generate(final_response), headers: { "Content-Type" => "application/json" } }
      )

    chat = LLM.chat(model: "gemini-2.5-flash")
    response = chat.with_tools(TestCalculator).ask("What is 2+2?")
    assert_equal "The answer is 4", response.content.to_s
  end

  def test_structured_output
    schema_response = gemini_chat_response(content: '{"name":"John","age":30}')
    stub_gemini_completion("gemini-2.5-flash", schema_response)

    chat = LLM.chat(model: "gemini-2.5-flash")
    chat.with_schema(
      name: "Person",
      schema: { type: "object", properties: { name: { type: "string" }, age: { type: "integer" } } }
    ).ask("Extract: John is 30")

    assert_requested(:post, GEMINI_URL) { |req|
      body = JSON.parse(req.body)
      body.dig("generationConfig", "responseMimeType") == "application/json"
    }
  end

  def test_uppercase_types_in_schema
    provider = LLM::Providers::Gemini.new(LLM.config)
    converted = provider.send(:convert_schema, { "type" => "object", "properties" => { "name" => { "type" => "string" } } })
    assert_equal "OBJECT", converted[:type]
    assert_equal "STRING", converted[:properties]["name"][:type]
  end
end
