# llm_rb

A zero-dependency Ruby gem for LLM chat completions, tool use, structured output, streaming, and image generation. Supports Anthropic, Google Gemini, and OpenAI-compatible APIs (including local models via llama.cpp / LM Studio).

## Install

```ruby
gem "llm_rb"
```

## Setup

```ruby
require "llm"

LLM.configure do |c|
  c.openai_api_key    = ENV["OPENAI_API_KEY"]
  c.anthropic_api_key = ENV["ANTHROPIC_API_KEY"]
  c.gemini_api_key    = ENV["GEMINI_API_KEY"]
end
```

For local models, point the OpenAI base URL at your server:

```ruby
LLM.configure { |c| c.openai_api_base = "http://localhost:1234" }
chat = LLM.chat(model: "my-local-model", provider: :openai)
```

## Usage

### Chat

Provider is inferred from the model name (`claude*` → Anthropic, `gemini*` → Gemini, else → OpenAI).

```ruby
chat = LLM.chat(model: "claude-sonnet-4-6")
response = chat.ask("Hello!")
puts response.content  # => "Hello! How can I help?"

chat.ask("Follow up")  # conversation history maintained
```

### Streaming

```ruby
chat.ask("Tell me a story") { |chunk| print chunk.content }
```

### Tools

```ruby
class Calculator < LLM::Tool
  description "Performs math"
  param :expression, type: :string, desc: "Math expression"
  def execute(expression:) = eval(expression).to_s
end

chat.with_tools(Calculator).ask("What is 123 * 456?")
```

### Structured Output

```ruby
chat.with_schema(
  name: "Person",
  schema: {
    type: "object",
    properties: { name: { type: "string" }, age: { type: "integer" } },
    required: ["name", "age"]
  }
).ask("Extract: John is 30")
# => '{"name":"John","age":30}'
```

### Image Generation

```ruby
LLM.paint("A sunset", model: "dall-e-3").save("sunset.png")
```

### Chainable Configuration

```ruby
chat.with_instructions("You are helpful")
    .with_temperature(0.5)
    .with_model("gemini-3-flash-preview")
    .ask("Hi")
```

## Tests

```sh
bundle install

# Unit tests (stubbed HTTP, no API keys needed)
bundle exec rake test

# Integration tests (requires API keys in env)
ruby test/integration_test.rb
```

## License

MIT
