# frozen_string_literal: true

require "securerandom"

module LLM
  module Providers
    class Gemini < Provider
      module Chat
        def complete(messages, model:, tools: nil, schema: nil, temperature: nil, stream: nil, &block)
          if stream && block_given?
            url = "#{base_url}/v1beta/models/#{model}:streamGenerateContent?alt=sse&key=#{config.gemini_api_key}"
            payload = render_payload(messages, tools: tools, schema: schema, temperature: temperature)

            accumulator = StreamAccumulator.new
            post(url, payload, headers: default_headers, stream: true) do |data|
              chunk_hash = build_chunk(data)
              next unless chunk_hash
              accumulator.add(chunk_hash)
              if chunk_hash[:content]
                chunk = Chunk.new(content: chunk_hash[:content], model_id: model)
                block.call(chunk)
              end
            end
            accumulator.to_message
          else
            url = "#{base_url}/v1beta/models/#{model}:generateContent?key=#{config.gemini_api_key}"
            payload = render_payload(messages, tools: tools, schema: schema, temperature: temperature)
            data = post(url, payload, headers: default_headers)
            parse_completion_response(data, model)
          end
        end

        private

        def render_payload(messages, tools:, schema:, temperature:)
          system_text, contents = extract_system_and_contents(messages)

          payload = { contents: contents }
          payload[:systemInstruction] = { parts: [{ text: system_text }] } if system_text

          generation_config = {}
          generation_config[:temperature] = temperature if temperature

          if schema
            generation_config[:responseMimeType] = "application/json"
            generation_config[:responseSchema] = convert_schema(schema.schema)
          end

          payload[:generationConfig] = generation_config unless generation_config.empty?

          formatted_tools = format_tools(tools)
          payload[:tools] = formatted_tools if formatted_tools

          payload
        end

        def extract_system_and_contents(messages)
          system_text = nil
          contents = []

          messages.each do |msg|
            if msg.system?
              system_text = msg.content.to_s
            elsif msg.tool?
              contents << {
                role: "user",
                parts: [{
                  functionResponse: {
                    name: msg.tool_call_id,
                    response: { result: msg.content.to_s }
                  }
                }]
              }
            elsif msg.assistant? && msg.tool_calls && !msg.tool_calls.empty?
              parts = []
              parts << { text: msg.content.to_s } unless msg.content.to_s.empty?
              msg.tool_calls.each do |tc|
                part = {
                  functionCall: {
                    name: tc.name,
                    args: tc.arguments
                  }
                }
                part[:thoughtSignature] = tc.metadata[:thought_signature] if tc.metadata[:thought_signature]
                parts << part
              end
              contents << { role: "model", parts: parts }
            else
              role = msg.assistant? ? "model" : "user"
              contents << {
                role: role,
                parts: format_content(msg.content)
              }
            end
          end

          [system_text, contents]
        end

        def parse_completion_response(data, model)
          candidate = data.dig("candidates", 0)
          parts = candidate&.dig("content", "parts") || []

          text_parts = parts.select { |p| p["text"] }.map { |p| p["text"] }
          tool_calls = parse_tool_calls(parts)
          usage = data["usageMetadata"] || {}

          Message.new(
            role: :assistant,
            content: text_parts.empty? ? nil : text_parts.join,
            tool_calls: tool_calls,
            tokens: Tokens.new(
              input: usage["promptTokenCount"] || 0,
              output: usage["candidatesTokenCount"] || 0,
              cached: usage["cachedContentTokenCount"] || 0
            ),
            model_id: model
          )
        end
      end
    end
  end
end
