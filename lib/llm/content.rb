# frozen_string_literal: true

module LLM
  class Content
    attr_accessor :text, :attachments

    def initialize(text: nil, attachments: [])
      @text = text
      @attachments = attachments
    end

    def to_s
      text.to_s
    end

    def simple?
      attachments.empty?
    end
  end
end
