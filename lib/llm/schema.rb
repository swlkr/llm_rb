# frozen_string_literal: true

module LLM
  class Schema
    attr_reader :name, :schema

    def initialize(name:, schema:)
      @name = name
      @schema = schema
    end
  end
end
