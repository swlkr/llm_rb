# frozen_string_literal: true

module LLM
  module Providers
    class OpenAI < Provider
      module Images
        def paint(prompt, model: "dall-e-3", size: "1024x1024", **opts)
          url = "#{base_url}/v1/images/generations"
          payload = {
            model: model,
            prompt: prompt,
            n: 1,
            size: size,
            response_format: "b64_json"
          }

          data = post(url, payload, headers: default_headers)
          img_data = data.dig("data", 0)

          Image.new(
            data: img_data["b64_json"],
            url: img_data["url"],
            revised_prompt: img_data["revised_prompt"],
            model_id: model,
            mime_type: "image/png"
          )
        end
      end
    end
  end
end
