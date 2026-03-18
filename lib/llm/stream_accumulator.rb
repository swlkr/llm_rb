# frozen_string_literal: true

module LLM
  class StreamAccumulator
    attr_reader :content, :tool_calls_data, :tokens, :model_id

    def initialize
      @content = +""
      @tool_calls_data = {}
      @tokens = Tokens.new
      @model_id = nil
    end

    def add(chunk_hash)
      @content << chunk_hash[:content].to_s if chunk_hash[:content]
      @model_id = chunk_hash[:model_id] if chunk_hash[:model_id]

      if chunk_hash[:tool_call_id]
        id = chunk_hash[:tool_call_id]
        @tool_calls_data[id] ||= { id: id, name: nil, arguments: +"" }
        @tool_calls_data[id][:name] = chunk_hash[:tool_call_name] if chunk_hash[:tool_call_name]
        @tool_calls_data[id][:arguments] << chunk_hash[:tool_call_arguments].to_s if chunk_hash[:tool_call_arguments]
      end

      if chunk_hash[:input_tokens]
        @tokens.input = chunk_hash[:input_tokens]
      end
      if chunk_hash[:output_tokens]
        @tokens.output = chunk_hash[:output_tokens]
      end
      if chunk_hash[:cached_tokens]
        @tokens.cached = chunk_hash[:cached_tokens]
      end
    end

    def to_message
      tool_calls = @tool_calls_data.values.map do |tc|
        args = tc[:arguments].empty? ? {} : JSON.parse(tc[:arguments])
        ToolCall.new(id: tc[:id], name: tc[:name], arguments: args)
      end

      Message.new(
        role: :assistant,
        content: @content.empty? ? nil : @content,
        tool_calls: tool_calls.empty? ? nil : tool_calls,
        tokens: @tokens,
        model_id: @model_id
      )
    end
  end
end
