# frozen_string_literal: true

module LLM
  module Providers
    class Gemini < Provider
      module Streaming
        def build_chunk(data)
          return nil unless data

          candidate = data.dig("candidates", 0)
          parts = candidate&.dig("content", "parts") || []
          usage = data["usageMetadata"]

          chunk = {}

          parts.each do |part|
            if part["text"]
              chunk[:content] = (chunk[:content] || "") + part["text"]
            elsif part["functionCall"]
              call = part["functionCall"]
              chunk[:tool_call_id] = "call_#{SecureRandom.hex(12)}"
              chunk[:tool_call_name] = call["name"]
              chunk[:tool_call_arguments] = JSON.generate(call["args"] || {})
            end
          end

          if usage
            chunk[:input_tokens] = usage["promptTokenCount"] if usage["promptTokenCount"]
            chunk[:output_tokens] = usage["candidatesTokenCount"] if usage["candidatesTokenCount"]
          end

          chunk.empty? ? nil : chunk
        end
      end
    end
  end
end
