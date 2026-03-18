# frozen_string_literal: true

module LLM
  module Providers
    class Anthropic < Provider
      module Media
        def format_content(content)
          return [{ type: "text", text: content.text }] if content.simple?

          parts = []

          content.attachments.each do |att|
            if att.image?
              parts << {
                type: "image",
                source: {
                  type: "base64",
                  media_type: att.mime_type,
                  data: att.base64_data
                }
              }
            elsif att.pdf?
              parts << {
                type: "document",
                source: {
                  type: "base64",
                  media_type: att.mime_type,
                  data: att.base64_data
                }
              }
            end
          end

          parts << { type: "text", text: content.text } if content.text
          parts
        end
      end
    end
  end
end
