# frozen_string_literal: true

module LLM
  module Providers
    class Anthropic < Provider
      module Chat
        def complete(messages, model:, tools: nil, schema: nil, temperature: nil, stream: nil, &block)
          payload = render_payload(messages, model: model, tools: tools, schema: schema,
                                  temperature: temperature, stream: stream)
          url = "#{base_url}/v1/messages"

          if stream && block_given?
            accumulator = StreamAccumulator.new
            post(url, payload, headers: default_headers, stream: true) do |data|
              chunk_hash = build_chunk(data)
              next unless chunk_hash
              accumulator.add(chunk_hash)
              if chunk_hash[:content]
                chunk = Chunk.new(content: chunk_hash[:content], model_id: chunk_hash[:model_id])
                block.call(chunk)
              end
            end
            accumulator.to_message
          else
            data = post(url, payload, headers: default_headers)
            parse_completion_response(data)
          end
        end

        private

        def render_payload(messages, model:, tools:, schema:, temperature:, stream:)
          system_text, api_messages = extract_system_and_messages(messages)

          payload = {
            model: model,
            messages: api_messages,
            max_tokens: 4096
          }

          payload[:system] = system_text if system_text
          payload[:temperature] = temperature if temperature
          payload[:stream] = true if stream

          # Anthropic lacks native structured output — fake it by forcing a tool_use call
          if schema
            schema_tool = {
              name: schema.name,
              description: "Extract structured data",
              input_schema: schema.schema
            }
            payload[:tools] = [schema_tool]
            payload[:tool_choice] = { type: "tool", name: schema.name }
          elsif tools && !tools.empty?
            payload[:tools] = format_tools(tools)
            payload[:tool_choice] = { type: "auto" }
          end

          payload
        end

        def extract_system_and_messages(messages)
          system_text = nil
          api_messages = []

          messages.each do |msg|
            if msg.system?
              system_text = msg.content.to_s
            elsif msg.tool?
              # Anthropic requires tool results as content blocks inside a user message, not a separate role
              if api_messages.last && api_messages.last[:role] == "user" &&
                 api_messages.last[:content].is_a?(Array) &&
                 api_messages.last[:content].any? { |c| c[:type] == "tool_result" }
                api_messages.last[:content] << format_tool_result(msg.tool_call_id, msg.content.to_s)
              else
                api_messages << {
                  role: "user",
                  content: [format_tool_result(msg.tool_call_id, msg.content.to_s)]
                }
              end
            elsif msg.assistant? && msg.tool_calls && !msg.tool_calls.empty?
              content_blocks = []
              content_blocks << { type: "text", text: msg.content.to_s } unless msg.content.to_s.empty?
              msg.tool_calls.each do |tc|
                content_blocks << {
                  type: "tool_use",
                  id: tc.id,
                  name: tc.name,
                  input: tc.arguments
                }
              end
              api_messages << { role: "assistant", content: content_blocks }
            else
              api_messages << {
                role: msg.role.to_s,
                content: format_content(msg.content)
              }
            end
          end

          [system_text, api_messages]
        end

        def parse_completion_response(data)
          content_blocks = data["content"] || []
          text_parts = content_blocks.select { |b| b["type"] == "text" }.map { |b| b["text"] }
          tool_calls = parse_tool_calls(content_blocks)
          usage = data["usage"] || {}

          # Schema responses come back as tool_use input — unwrap to plain JSON for the caller
          content_text = if tool_calls && !tool_calls.empty? && text_parts.empty?
                           JSON.generate(tool_calls.first.arguments)
                         else
                           text_parts.join
                         end

          Message.new(
            role: :assistant,
            content: content_text.empty? ? nil : content_text,
            tool_calls: tool_calls,
            tokens: Tokens.new(
              input: usage["input_tokens"] || 0,
              output: usage["output_tokens"] || 0,
              cached: usage.dig("cache_read_input_tokens") || 0
            ),
            model_id: data["model"]
          )
        end
      end
    end
  end
end
