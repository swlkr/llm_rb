# frozen_string_literal: true

module LLM
  class Message
    attr_accessor :role, :content, :tool_calls, :tool_call_id, :tokens, :model_id

    def initialize(role:, content: nil, tool_calls: nil, tool_call_id: nil, tokens: nil, model_id: nil)
      @role = role.to_sym
      @content = wrap_content(content)
      @tool_calls = tool_calls || []
      @tool_call_id = tool_call_id
      @tokens = tokens
      @model_id = model_id
    end

    def assistant?
      role == :assistant
    end

    def user?
      role == :user
    end

    def tool?
      role == :tool
    end

    def system?
      role == :system
    end

    private

    def wrap_content(value)
      case value
      when Content then value
      when String then Content.new(text: value)
      when nil then Content.new
      else value
      end
    end
  end
end
