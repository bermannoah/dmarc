##
# Adapted from gist: https://gist.github.com/zerothabhishek/3015666
# Original author: zerothabhishek
##

require 'nokogiri'
require 'net/http'
require 'uri'
require 'resolv'
require 'csv'

module Alexa
  #
  # Fetches an HTTPS page and returns its body.
  #
  # @param [String] url
  #   The URL to fetch.
  #
  # @return [String]
  #   The response body.
  #
  # @raise [ArgumentError]
  #   The URL is not HTTPS.
  #
  def self.fetch(url)
    uri = URI(url)
    raise ArgumentError, "only HTTPS URLs are allowed" unless uri.is_a?(URI::HTTPS)

    Net::HTTP.start(
      uri.host,
      uri.port,
      use_ssl: true,
      open_timeout: 10,
      read_timeout: 30
    ) do |http|
      response = http.request(Net::HTTP::Get.new(uri))
      response.value
      return response.body
    end
  end
end

namespace :alexa do
  desc 'Scrapes the Alexa Top 500 and updates spec/data/alexa.csv'
  task :scrape do
    resolver = Resolv::DNS.new

    CSV.open("spec/data/alexa.csv","w") do |csv|
      (0..19).each do |i|
        url = "https://www.alexa.com/topsites/global;#{i}"
        doc = Nokogiri::HTML(Alexa.fetch(url))

        doc.css(".site-listing").each do |li|
          begin
            site_name = li.css(".desc-container .desc-paragraph a")[0].content
            site_rank = li.css(".count")[0].content

            puts "Resolving #{site_name} ..."
            dmarc = begin
                      resolver.getresource(
                        "_dmarc.#{site_name.downcase}",
                        Resolv::DNS::Resource::IN::TXT
                      ).strings.join
                    rescue Resolv::ResolvError
                    end

            csv << [site_rank, site_name, dmarc]
          rescue => exception
            warn exception.message
          end
        end
      end
    end
  end
end
