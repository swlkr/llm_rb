# frozen_string_literal: true

module LLM
  module Providers
    class OpenAI < Provider
      module Media
        def format_content(content)
          return content.text if content.simple?

          parts = []
          parts << { type: "text", text: content.text } if content.text

          content.attachments.each do |att|
            if att.image?
              url = if att.url?
                      att.source
                    else
                      "data:#{att.mime_type};base64,#{att.base64_data}"
                    end
              parts << { type: "image_url", image_url: { url: url } }
            end
          end

          parts
        end
      end
    end
  end
end
