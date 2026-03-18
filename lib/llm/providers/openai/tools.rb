# frozen_string_literal: true

module LLM
  module Providers
    class OpenAI < Provider
      module Tools
        def tool_for(tool_class)
          {
            type: "function",
            function: {
              name: tool_class.tool_name,
              description: tool_class.description,
              parameters: tool_class.to_json_schema
            }
          }
        end

        def format_tools(tool_classes)
          return nil if tool_classes.nil? || tool_classes.empty?
          tool_classes.values.map { |tc| tool_for(tc) }
        end

        def parse_tool_calls(data)
          return nil unless data
          data.map do |tc|
            ToolCall.new(
              id: tc["id"],
              name: tc.dig("function", "name"),
              arguments: tc.dig("function", "arguments") || "{}"
            )
          end
        end

        def build_tool_choice(tool_classes)
          return nil if tool_classes.nil? || tool_classes.empty?
          "auto"
        end
      end
    end
  end
end
