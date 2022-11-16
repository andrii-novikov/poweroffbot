require 'bundler'
require 'net/http'

Bundler.require

def send_message(message)
  token = ENV['TELEGRAM_TOKEN']
  chat_id = ENV['TELEGRAM_CHAT_ID']

  if token.nil? || chat_id.nil?
    puts 'TELEGRAM_TOKEN or TELEGRAM_CHAT_ID is not set'
    return
  end
  
  Net::HTTP.post_form(
    URI("https://api.telegram.org/bot#{token}/sendMessage"), chat_id: chat_id, text: message
  )
end

begin 
  csrf_token = ENV['CSRF_TOKEN']
  city = ENV['CITY']
  street = ENV['STREET']
  uri = URI('https://poweroff.loe.lviv.ua/search_off')
  uri.query = URI.encode_www_form({csrfmiddlewaretoken: csrf_token, city: city, street: street, otg: nil})
  
  response = Net::HTTP.get_response(uri)
rescue => e
  send_message("Error: #{e.message}")
end

if response.code != '200'
  send_message("Error: #{response.code}")
  exit
end

CITY_INDEX = 1
STREET_INDEX = 2
HOUSE_INDEX = 3
OFF_TYPE_INDEX = 4
CAUSE_INDEX = 5
OFF_START = 6
OFF_END = 7

data = Nokogiri::HTML(response.body).css('div.col-md-12 div table tbody').map do |tr|
  columns = tr.css('td')

  {
    city: columns[CITY_INDEX].text,
    street: columns[STREET_INDEX].text,
    house: columns[HOUSE_INDEX].text,
    off_type: columns[OFF_TYPE_INDEX].text,
    cause: columns[CAUSE_INDEX].text,
    off_start: columns[OFF_START].text,
    off_end: columns[OFF_END].text
  }
end

if data.empty?
  send_message("No power offs")
  exit
end

on_my_street = data.select { |d| d[:street] =~ /козловского|трускавецька|козл/i } 

if on_my_street.any?
  message = on_my_street.map { |d| "#{d[:street]} #{d[:house]} #{d[:off_start]} - #{d[:off_end]}" }.join("\n")
  send_message("Света не будет на твоей улице: \n#{message}")
elsif ARGV.include? '--send-all'
  streets = data.map { |d| d[:street] }.uniq
  message =  "Света не будет на:\n #{streets.join("\n")}"
  send_message(message)
end