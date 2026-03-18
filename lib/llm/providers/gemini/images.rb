# frozen_string_literal: true

module LLM
  module Providers
    class Gemini < Provider
      module Images
        def paint(prompt, model: "imagen-3.0-generate-002", size: "1024x1024", **opts)
          url = "#{base_url}/v1beta/models/#{model}:predict?key=#{config.gemini_api_key}"
          payload = {
            instances: [{ prompt: prompt }],
            parameters: {
              sampleCount: 1,
              aspectRatio: size_to_aspect_ratio(size)
            }
          }

          data = post(url, payload, headers: default_headers)
          prediction = data.dig("predictions", 0)

          Image.new(
            data: prediction&.dig("bytesBase64Encoded"),
            mime_type: prediction&.dig("mimeType") || "image/png",
            model_id: model
          )
        end

        private

        def size_to_aspect_ratio(size)
          case size
          when "1024x1024", "512x512" then "1:1"
          when "1024x1792", "512x768" then "9:16"
          when "1792x1024", "768x512" then "16:9"
          else "1:1"
          end
        end
      end
    end
  end
end
