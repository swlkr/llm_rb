# frozen_string_literal: true

module LLM
  module Providers
    class Gemini < Provider
      module Media
        def format_content(content)
          parts = []

          if content.attachments && !content.attachments.empty?
            content.attachments.each do |att|
              if att.image? || att.pdf?
                parts << {
                  inlineData: {
                    mimeType: att.mime_type,
                    data: att.base64_data
                  }
                }
              end
            end
          end

          parts << { text: content.text } if content.text
          parts
        end
      end
    end
  end
end
