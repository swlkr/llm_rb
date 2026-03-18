# frozen_string_literal: true

module LLM
  Chunk = Struct.new(:content, :tool_calls, :tokens, :model_id, keyword_init: true) do
    def initialize(content: nil, tool_calls: nil, tokens: nil, model_id: nil)
      super
    end
  end
end
