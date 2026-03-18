# frozen_string_literal: true

module LLM
  module Providers
    class Anthropic < Provider
      module Streaming
        def build_chunk(data)
          type = data["type"]

          case type
          when "message_start"
            msg = data["message"] || {}
            usage = msg["usage"] || {}
            {
              model_id: msg["model"],
              input_tokens: usage["input_tokens"],
              cached_tokens: usage.dig("cache_read_input_tokens")
            }
          when "content_block_start"
            block = data["content_block"] || {}
            if block["type"] == "tool_use"
              @current_tool_id = block["id"]
              {
                tool_call_id: block["id"],
                tool_call_name: block["name"]
              }
            else
              nil
            end
          when "content_block_delta"
            delta = data["delta"] || {}
            case delta["type"]
            when "text_delta"
              { content: delta["text"] }
            when "input_json_delta"
              {
                tool_call_id: @current_tool_id,
                tool_call_arguments: delta["partial_json"]
              }
            else
              nil
            end
          when "message_delta"
            usage = data["usage"] || {}
            { output_tokens: usage["output_tokens"] }
          else
            nil
          end
        end
      end
    end
  end
end
