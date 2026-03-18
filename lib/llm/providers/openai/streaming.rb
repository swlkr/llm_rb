# frozen_string_literal: true

module LLM
  module Providers
    class OpenAI < Provider
      module Streaming
        def build_chunk(data)
          return nil unless data

          choice = data.dig("choices", 0)
          delta = choice&.dig("delta") || {}
          usage = data["usage"]

          chunk = { model_id: data["model"] }
          chunk[:content] = delta["content"] if delta["content"]

          if delta["tool_calls"]
            tc = delta["tool_calls"][0]
            if tc
              chunk[:tool_call_id] = tc["id"] if tc["id"]
              chunk[:tool_call_name] = tc.dig("function", "name") if tc.dig("function", "name")
              chunk[:tool_call_arguments] = tc.dig("function", "arguments") if tc.dig("function", "arguments")
            end
          end

          if usage
            chunk[:input_tokens] = usage["prompt_tokens"] if usage["prompt_tokens"]
            chunk[:output_tokens] = usage["completion_tokens"] if usage["completion_tokens"]
          end

          chunk
        end
      end
    end
  end
end
