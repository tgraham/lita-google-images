require "lita"

module Lita
  module Handlers
    class GoogleImages < Handler
      # URL = "https://ajax.googleapis.com/ajax/services/search/images"
      URL = "https://www.googleapis.com/customsearch/v1/"
      VALID_SAFE_VALUES = %w(high medium off)

      config :safe_search, types: [String, Symbol], default: :high do
        validate do |value|
          unless VALID_SAFE_VALUES.include?(value.to_s.strip)
            "valid values are :high, :medium, or :off"
          end
        end
      end

      config :cse_key
      config :cse_cx

      route(/(?:image|img)(?:\s+me)? (.+)/, :fetch, command: true, help: {
        "image QUERY" => "Displays a random image from Google Images matching the query."
      })

      def fetch(response)
        query = response.matches[0][0]

        http_response = http.get(
          URL,
          key: config.cse_key,
          cx: config.cse_cx,
          q: query,
          safe: config.safe_search,
          num: 8,
          start: rand(1..100),
          imgSize: "medium",
          imgType: "photo",
          searchType: "image",
          fileType: "jpg"
        )

        data = MultiJson.load(http_response.body)

        if http_response.status == 200
          choice = data["items"].sample
          if choice
            response.reply ensure_extension(choice["link"])
          else
            response.reply %{No images found for "#{query}".}
          end
        else
          Lita.logger.warn(
            "Couldn't get image from Google, sorry!"
          )
        end
      end

      private

      def ensure_extension(url)
        if [".gif", ".jpg", ".jpeg", ".png"].any? { |ext| url.end_with?(ext) }
          url
        else
          "#{url}#.png"
        end
      end
    end

    Lita.register_handler(GoogleImages)
  end
end
