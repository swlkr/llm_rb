# frozen_string_literal: true

require_relative "../lib/llm"
require "minitest/autorun"

# Integration tests — run with: ruby test/integration_test.rb
# Requires API keys in environment (source ~/.zshrc if needed)

class Calculator < LLM::Tool
  description "Performs math calculations"
  param :expression, type: :string, desc: "Math expression to evaluate"

  def execute(expression:)
    eval(expression).to_s
  end
end

class IntegrationTest < Minitest::Test
  def setup
    LLM.reset!
    LLM.configure do |c|
      c.anthropic_api_key = ENV["ANTHROPIC_API_KEY"]
      c.gemini_api_key = ENV["GEMINI_API_KEY"]
      c.openai_api_key = ENV["OPENAI_API_KEY"]
      c.openai_api_base = ENV["LM_BASE_URL"] if ENV["LM_BASE_URL"]
    end
  end

  # --- Anthropic ---

  if ENV["ANTHROPIC_API_KEY"]
    def test_anthropic_basic_chat
      chat = LLM.chat(model: "claude-sonnet-4-6")
      response = chat.ask("Say hello in exactly one word.")
      assert response.content.to_s.length > 0
      assert response.tokens.input > 0
      puts "\n  Anthropic basic: #{response.content.to_s.inspect} (#{response.tokens.total} tokens)"
    end

    def test_anthropic_conversation
      chat = LLM.chat(model: "claude-sonnet-4-6")
      chat.ask("My name is TestBot.")
      response = chat.ask("What is my name?")
      assert_match(/testbot/i, response.content.to_s)
      puts "\n  Anthropic conversation: #{response.content.to_s.inspect}"
    end

    def test_anthropic_streaming
      chat = LLM.chat(model: "claude-sonnet-4-6")
      chunks = []
      response = chat.ask("Count from 1 to 5, one number per line.") { |c| chunks << c.content }
      assert chunks.length > 1, "Expected multiple chunks, got #{chunks.length}"
      assert response.content.to_s.length > 0
      puts "\n  Anthropic streaming: #{chunks.length} chunks, final: #{response.content.to_s.lines.count} lines"
    end

    def test_anthropic_tools
      chat = LLM.chat(model: "claude-sonnet-4-6")
      response = chat.with_tools(Calculator).ask("What is 123 * 456? Use the calculator tool.")
      assert_match(/56,?088/, response.content.to_s)
      puts "\n  Anthropic tools: #{response.content.to_s.inspect}"
    end

    def test_anthropic_structured_output
      chat = LLM.chat(model: "claude-sonnet-4-6")
      response = chat.with_schema(
        name: "Person",
        schema: {
          type: "object",
          properties: { name: { type: "string" }, age: { type: "integer" } },
          required: %w[name age]
        }
      ).ask("Extract: John is 30 years old")
      parsed = JSON.parse(response.content.to_s)
      assert_equal "John", parsed["name"]
      assert_equal 30, parsed["age"]
      puts "\n  Anthropic structured: #{parsed.inspect}"
    end

    def test_anthropic_streaming_tools
      chat = LLM.chat(model: "claude-sonnet-4-6")
      chunks = []
      response = chat.with_tools(Calculator).ask("What is 99 * 101? Use the calculator tool.") { |c|
        chunks << c.content if c.content
      }
      assert_match(/9,?999/, response.content.to_s)
      assert chunks.length > 0, "Expected streaming chunks"
      puts "\n  Anthropic streaming tools: #{chunks.length} chunks, result: #{response.content.to_s.inspect}"
    end

    def test_anthropic_streaming_conversation
      chat = LLM.chat(model: "claude-sonnet-4-6")
      chunks1 = []
      chat.ask("My favorite color is blue.") { |c| chunks1 << c.content if c.content }
      assert chunks1.length > 0

      chunks2 = []
      response = chat.ask("What is my favorite color?") { |c| chunks2 << c.content if c.content }
      assert chunks2.length > 0
      assert_match(/blue/i, response.content.to_s)
      puts "\n  Anthropic streaming conversation: #{chunks2.length} chunks, result: #{response.content.to_s.inspect}"
    end

    def test_anthropic_instructions
      chat = LLM.chat(model: "claude-sonnet-4-6")
      response = chat.with_instructions("Always respond in ALL CAPS.").ask("Say hi")
      # At least some uppercase
      assert response.content.to_s.match?(/[A-Z]{2,}/)
      puts "\n  Anthropic instructions: #{response.content.to_s.inspect}"
    end
  end

  # --- Gemini ---

  if ENV["GEMINI_API_KEY"]
    def test_gemini_basic_chat
      chat = LLM.chat(model: "gemini-3-flash-preview")
      response = chat.ask("Say hello in exactly one word.")
      assert response.content.to_s.length > 0
      assert response.tokens.input > 0
      puts "\n  Gemini basic: #{response.content.to_s.inspect} (#{response.tokens.total} tokens)"
    end

    def test_gemini_conversation
      chat = LLM.chat(model: "gemini-3-flash-preview")
      chat.ask("My name is TestBot.")
      response = chat.ask("What is my name?")
      assert_match(/testbot/i, response.content.to_s)
      puts "\n  Gemini conversation: #{response.content.to_s.inspect}"
    end

    def test_gemini_streaming
      chat = LLM.chat(model: "gemini-3-flash-preview")
      chunks = []
      response = chat.ask("Count from 1 to 5, one number per line.") { |c| chunks << c.content }
      assert chunks.length > 0, "Expected at least one chunk"
      assert response.content.to_s.length > 0
      puts "\n  Gemini streaming: #{chunks.length} chunks"
    end

    def test_gemini_streaming_tools
      chat = LLM.chat(model: "gemini-3-flash-preview")
      chunks = []
      response = chat.with_tools(Calculator).ask("What is 99 * 101? Use the calculator tool.") { |c|
        chunks << c.content if c.content
      }
      assert_match(/9,?999/, response.content.to_s)
      assert chunks.length > 0, "Expected streaming chunks"
      puts "\n  Gemini streaming tools: #{chunks.length} chunks, result: #{response.content.to_s.inspect}"
    end

    def test_gemini_streaming_conversation
      chat = LLM.chat(model: "gemini-3-flash-preview")
      chunks1 = []
      chat.ask("My favorite color is blue.") { |c| chunks1 << c.content if c.content }
      assert chunks1.length > 0

      chunks2 = []
      response = chat.ask("What is my favorite color?") { |c| chunks2 << c.content if c.content }
      assert chunks2.length > 0
      assert_match(/blue/i, response.content.to_s)
      puts "\n  Gemini streaming conversation: #{chunks2.length} chunks, result: #{response.content.to_s.inspect}"
    end

    def test_gemini_tools
      chat = LLM.chat(model: "gemini-3-flash-preview")
      response = chat.with_tools(Calculator).ask("What is 123 * 456? Use the calculator tool.")
      assert_match(/56,?088/, response.content.to_s)
      puts "\n  Gemini tools: #{response.content.to_s.inspect}"
    end

    def test_gemini_structured_output
      chat = LLM.chat(model: "gemini-3-flash-preview")
      response = chat.with_schema(
        name: "Person",
        schema: {
          type: "object",
          properties: { name: { type: "string" }, age: { type: "integer" } },
          required: %w[name age]
        }
      ).ask("Extract: John is 30 years old")
      parsed = JSON.parse(response.content.to_s)
      assert_equal "John", parsed["name"]
      assert_equal 30, parsed["age"]
      puts "\n  Gemini structured: #{parsed.inspect}"
    end
  end

  # --- OpenAI-compatible (local LM Studio) ---

  if ENV["LM_BASE_URL"] && ENV["LM_MODEL"]
    def test_local_basic_chat
      chat = LLM.chat(model: ENV["LM_MODEL"], provider: :openai)
      response = chat.ask("Say hello in exactly one word.")
      assert response.content.to_s.length > 0
      puts "\n  Local LM basic: #{response.content.to_s.inspect}"
    end

    def test_local_conversation
      chat = LLM.chat(model: ENV["LM_MODEL"], provider: :openai)
      chat.ask("My name is TestBot.")
      response = chat.ask("What is my name?")
      puts "\n  Local LM conversation: #{response.content.to_s.inspect}"
      # Local models may not always recall, so just check we got a response
      assert response.content.to_s.length > 0
    end

    def test_local_streaming_conversation
      chat = LLM.chat(model: ENV["LM_MODEL"], provider: :openai)
      chunks1 = []
      chat.ask("My favorite color is blue.") { |c| chunks1 << c.content if c.content }
      assert chunks1.length > 0

      chunks2 = []
      response = chat.ask("What is my favorite color?") { |c| chunks2 << c.content if c.content }
      assert chunks2.length > 0
      assert response.content.to_s.length > 0
      puts "\n  Local LM streaming conversation: #{chunks2.length} chunks, result: #{response.content.to_s.inspect}"
    end

    def test_local_streaming
      chat = LLM.chat(model: ENV["LM_MODEL"], provider: :openai)
      chunks = []
      response = chat.ask("Count from 1 to 3.") { |c| chunks << c.content }
      assert chunks.length > 0
      assert response.content.to_s.length > 0
      puts "\n  Local LM streaming: #{chunks.length} chunks"
    end
  end
end
