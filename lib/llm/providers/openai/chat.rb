# frozen_string_literal: true

module LLM
  module Providers
    class OpenAI < Provider
      module Chat
        def complete(messages, model:, tools: nil, schema: nil, temperature: nil, stream: nil, &block)
          payload = render_payload(messages, model: model, tools: tools, schema: schema,
                                  temperature: temperature, stream: stream)
          url = "#{base_url}/v1/chat/completions"

          if stream && block_given?
            accumulator = StreamAccumulator.new
            post(url, payload, headers: default_headers, stream: true) do |data|
              chunk_hash = build_chunk(data)
              next unless chunk_hash
              accumulator.add(chunk_hash)
              chunk = Chunk.new(content: chunk_hash[:content], model_id: chunk_hash[:model_id])
              block.call(chunk)
            end
            accumulator.to_message
          else
            data = post(url, payload, headers: default_headers)
            parse_completion_response(data)
          end
        end

        private

        def render_payload(messages, model:, tools:, schema:, temperature:, stream:)
          payload = {
            model: model,
            messages: format_messages(messages)
          }

          payload[:temperature] = temperature if temperature
          payload[:stream] = true if stream
          payload[:stream_options] = { include_usage: true } if stream

          formatted_tools = format_tools(tools)
          if formatted_tools
            payload[:tools] = formatted_tools
            payload[:tool_choice] = build_tool_choice(tools)
          end

          if schema
            payload[:response_format] = {
              type: "json_schema",
              json_schema: {
                name: schema.name,
                schema: schema.schema,
                strict: true
              }
            }
          end

          payload
        end

        def format_messages(messages)
          messages.map do |msg|
            formatted = { role: msg.role.to_s }

            if msg.tool?
              formatted[:role] = "tool"
              formatted[:content] = msg.content.to_s
              formatted[:tool_call_id] = msg.tool_call_id
            elsif msg.tool_calls && !msg.tool_calls.empty?
              formatted[:content] = msg.content.to_s
              formatted[:tool_calls] = msg.tool_calls.map do |tc|
                {
                  id: tc.id,
                  type: "function",
                  function: { name: tc.name, arguments: JSON.generate(tc.arguments) }
                }
              end
            else
              formatted[:content] = format_content(msg.content)
            end

            formatted
          end
        end

        def parse_completion_response(data)
          choice = data.dig("choices", 0)
          msg = choice["message"]

          tool_calls = parse_tool_calls(msg["tool_calls"])
          usage = data["usage"] || {}

          Message.new(
            role: :assistant,
            content: msg["content"],
            tool_calls: tool_calls,
            tokens: Tokens.new(
              input: usage["prompt_tokens"] || 0,
              output: usage["completion_tokens"] || 0,
              cached: usage.dig("prompt_tokens_details", "cached_tokens") || 0
            ),
            model_id: data["model"]
          )
        end
      end
    end
  end
end
