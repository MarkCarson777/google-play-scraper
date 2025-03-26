require 'httparty'
require 'nokogiri'

class GooglePlayScraper
  BASE_URL = "https://play.google.com/store/apps/details"

  def self.fetch_app_details(app_id)
    response = HTTParty.get(BASE_URL, query: { id: app_id, hl: 'en', gl: 'us' })
    return nil unless response.success?

    doc = Nokogiri::HTML(response.body)
    extract_app_data(doc)
  rescue StandardError => e
    Rails.logger.error "Error fetching Google Play data: #{e.message}"
    nil
  end

  private

  def self.extract_app_data(doc)
    # Optional debug: Keep this for troubleshooting if needed
    rating_area = doc.at_css('div[itemprop="starRating"]')&.parent&.parent
    Rails.logger.info "Broader Rating Area HTML: #{rating_area&.to_html}" if rating_area

    review_text = doc.at_css('div.g1rdde')&.text&.strip
    review_count = parse_review_count(review_text) if review_text

    {
      title: doc.at_css('h1[itemprop="name"]')&.text&.strip,
      developer: doc.at_css('a[href*="/store/apps/dev"]')&.text&.strip,
      description: doc.at_css('div[itemprop="description"]')&.text&.strip,
      rating: doc.at_css('div[aria-label*="Rated"]')&.text&.match(/[\d.]+/)&.to_s,
      review_count: review_count
    }
  end

  def self.parse_review_count(text)
    # Handle formats like "9.02M reviews", "1,234 reviews", "500K reviews"
    if text.match(/([\d.]+)(M|K)?\s*reviews/i)
      number = $1.to_f
      multiplier = $2&.downcase == 'm' ? 1_000_000 : $2&.downcase == 'k' ? 1_000 : 1
      (number * multiplier).to_i.to_s
    else
      text&.match(/[\d,]+/)&.to_s&.gsub(',', '') || 'Not found'
    end
  end
end
