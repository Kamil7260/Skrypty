require 'nokogiri'
require 'httparty'

USER_AGENT = "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"
HEADERS = {
  "User-Agent" => USER_AGENT,
  "Content-Type" => "application/json"
}

def get_search_query
  puts "Search for?"
  gets.chomp.gsub(/\s+/, "+")
end

def fetch_html(url)
  HTTParty.get(url, headers: HEADERS).body
end

def parse_document(html)
  Nokogiri::HTML(html)
end

def extract_titles_and_prices(document)
  titles = document.css("a > .a-text-normal").map(&:text)
  prices = document.css("span > .a-offscreen").map(&:text)
  titles.zip(prices).to_h
end

def display_data(data)
  puts "Data:\n" << data.map { |k, v| "#{k}: #{v}" }.join(", \n")
end

search_query = get_search_query
url = "https://www.amazon.com/s?k=#{search_query}"
html = fetch_html(url)
document = parse_document(html)
data = extract_titles_and_prices(document)
display_data(data)