# frozen_string_literal: true

require "test_helper"

class OpenAIProviderTest < Minitest::Test
  include TestHelpers

  def test_basic_chat
    stub_openai_completion(openai_chat_response(content: "Hi there!"))
    chat = LLM.chat(model: "gpt-4o")
    response = chat.ask("Hello")
    assert_equal "Hi there!", response.content.to_s
    assert response.assistant?
    assert_equal 10, response.tokens.input
    assert_equal 5, response.tokens.output
  end

  def test_conversation_history
    stub_openai_completion(openai_chat_response(content: "First"))
    chat = LLM.chat(model: "gpt-4o")
    chat.ask("Hello")
    assert_equal 2, chat.messages.size # user + assistant

    stub_openai_completion(openai_chat_response(content: "Second"))
    chat.ask("Follow up")
    assert_equal 4, chat.messages.size # 2 user + 2 assistant
  end

  def test_tool_use
    # First response: model calls the tool
    tool_response = openai_chat_response(
      content: nil,
      tool_calls: [{
        "id" => "call_123",
        "type" => "function",
        "function" => {
          "name" => "test_calculator",
          "arguments" => '{"expression":"2+2"}'
        }
      }]
    )
    # Second response: model gives final answer
    final_response = openai_chat_response(content: "The answer is 4")

    stub_request(:post, "https://api.openai.com/v1/chat/completions")
      .to_return(
        { status: 200, body: JSON.generate(tool_response), headers: { "Content-Type" => "application/json" } },
        { status: 200, body: JSON.generate(final_response), headers: { "Content-Type" => "application/json" } }
      )

    chat = LLM.chat(model: "gpt-4o")
    response = chat.with_tools(TestCalculator).ask("What is 2+2?")
    assert_equal "The answer is 4", response.content.to_s

    # Should have: user, assistant (tool_call), tool (result), assistant (final)
    assert_equal 4, chat.messages.size
  end

  def test_structured_output
    schema_response = openai_chat_response(content: '{"name":"John","age":30}')
    stub_openai_completion(schema_response)

    chat = LLM.chat(model: "gpt-4o")
    response = chat.with_schema(
      name: "Person",
      schema: { type: "object", properties: { name: { type: "string" }, age: { type: "integer" } }, required: %w[name age] }
    ).ask("Extract: John is 30")

    parsed = JSON.parse(response.content.to_s)
    assert_equal "John", parsed["name"]
    assert_equal 30, parsed["age"]
  end

  def test_with_instructions
    stub_openai_completion(openai_chat_response(content: "I am helpful"))
    chat = LLM.chat(model: "gpt-4o")
    chat.with_instructions("You are helpful").ask("Hi")

    # system + user + assistant
    assert_equal 3, chat.messages.size
    assert chat.messages[0].system?
    assert_equal "You are helpful", chat.messages[0].content.to_s
  end

  def test_with_temperature
    stub_openai_completion(openai_chat_response)
    chat = LLM.chat(model: "gpt-4o")
    chat.with_temperature(0.5).ask("Hi")

    assert_requested(:post, "https://api.openai.com/v1/chat/completions") { |req|
      JSON.parse(req.body)["temperature"] == 0.5
    }
  end

  def test_error_handling
    stub_request(:post, "https://api.openai.com/v1/chat/completions")
      .to_return(status: 401, body: JSON.generate({ "error" => { "message" => "Invalid API key" } }),
                 headers: { "Content-Type" => "application/json" })

    chat = LLM.chat(model: "gpt-4o")
    assert_raises(LLM::UnauthorizedError) { chat.ask("Hi") }
  end

  def test_chainable_api
    stub_openai_completion(openai_chat_response)
    chat = LLM.chat(model: "gpt-4o")
    result = chat.with_instructions("Be helpful").with_temperature(0.7)
    assert_same chat, result
  end
end
