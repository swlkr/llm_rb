# frozen_string_literal: true

require "json"

module LLM
  class ToolCall
    attr_reader :id, :name, :arguments, :metadata

    def initialize(id:, name:, arguments:, metadata: {})
      @id = id
      @name = name
      @arguments = arguments.is_a?(String) ? JSON.parse(arguments) : arguments
      @metadata = metadata
    end
  end
end
