# frozen_string_literal: true

module LLM
  module Providers
    class Gemini < Provider
      module Tools
        TYPE_MAP = {
          "string" => "STRING",
          "integer" => "INTEGER",
          "number" => "NUMBER",
          "boolean" => "BOOLEAN",
          "array" => "ARRAY",
          "object" => "OBJECT"
        }.freeze

        def tool_for(tool_class)
          {
            name: tool_class.tool_name,
            description: tool_class.description,
            parameters: convert_schema(tool_class.to_json_schema)
          }
        end

        def format_tools(tool_classes)
          return nil if tool_classes.nil? || tool_classes.empty?
          [{
            functionDeclarations: tool_classes.values.map { |tc| tool_for(tc) }
          }]
        end

        def parse_tool_calls(parts)
          return nil unless parts
          function_calls = parts.select { |p| p["functionCall"] }
          return nil if function_calls.empty?

          function_calls.map do |fc|
            call = fc["functionCall"]
            metadata = {}
            metadata[:thought_signature] = fc["thoughtSignature"] if fc["thoughtSignature"]
            ToolCall.new(
              id: "call_#{SecureRandom.hex(12)}",
              name: call["name"],
              arguments: call["args"] || {},
              metadata: metadata
            )
          end
        end

        def convert_schema(schema)
          return schema unless schema.is_a?(Hash)
          result = {}
          schema.each do |key, value|
            case key.to_s
            when "type"
              result[:type] = TYPE_MAP[value.to_s] || value.to_s.upcase
            when "properties"
              result[:properties] = value.transform_values { |v| convert_schema(v) }
            when "required"
              result[:required] = value
            when "description"
              result[:description] = value
            when "items"
              result[:items] = convert_schema(value)
            when "enum"
              result[:enum] = value
            else
              result[key.to_sym] = value
            end
          end
          result
        end
      end
    end
  end
end
