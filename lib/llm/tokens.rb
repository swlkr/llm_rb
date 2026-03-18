# frozen_string_literal: true

module LLM
  class Tokens
    attr_accessor :input, :output, :cached

    def initialize(input: 0, output: 0, cached: 0)
      @input = input
      @output = output
      @cached = cached
    end

    def total
      input + output
    end
  end
end
