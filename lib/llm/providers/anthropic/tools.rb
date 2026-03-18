# frozen_string_literal: true

module LLM
  module Providers
    class Anthropic < Provider
      module Tools
        def tool_for(tool_class)
          {
            name: tool_class.tool_name,
            description: tool_class.description,
            input_schema: tool_class.to_json_schema
          }
        end

        def format_tools(tool_classes)
          return nil if tool_classes.nil? || tool_classes.empty?
          tool_classes.values.map { |tc| tool_for(tc) }
        end

        def parse_tool_calls(content_blocks)
          return nil unless content_blocks
          tool_uses = content_blocks.select { |b| b["type"] == "tool_use" }
          return nil if tool_uses.empty?

          tool_uses.map do |tu|
            ToolCall.new(
              id: tu["id"],
              name: tu["name"],
              arguments: tu["input"] || {}
            )
          end
        end

        def build_tool_choice(tool_classes, schema: nil)
          if schema
            { type: "tool", name: schema.name }
          else
            { type: "auto" }
          end
        end

        def format_tool_result(tool_call_id, result)
          {
            type: "tool_result",
            tool_use_id: tool_call_id,
            content: result.to_s
          }
        end
      end
    end
  end
end
