# frozen_string_literal: true

require 'mail'
require 'httparty'
require 'nokogiri'
require 'open-uri'

class EmailParser
  def self.extract_json(email_source)
    email_content = fetch_email_content(email_source)
    mail = Mail.read_from_string(email_content)

    json_attachment = extract_json_attachment(mail)
    return json_attachment if json_attachment

    json_link = extract_first_json_link(mail.body.decoded)
    return json_link if json_link

    nil
  end

  private

  def self.fetch_email_content(email_source)
    if valid_url?(email_source)
      fetch_content_from_url(email_source)
    else
      fetch_content_from_file(email_source)
    end
  end

  def self.valid_url?(source)
    uri = URI.parse(source)
    %w[http https].include?(uri.scheme)
  rescue URI::InvalidURIError
    false
  end

  def self.fetch_content_from_url(url)
    uri = URI.parse(url)
    response = Net::HTTP.get_response(uri)

    case response
    when Net::HTTPSuccess
      response.body
    when Net::HTTPRedirection
      fetch_content_from_url(response['location']) # Follow the redirection
    else
      raise "Error fetching email from URL: #{response.message} (#{response.code})"
    end
  rescue SocketError => e
    raise "Network error while fetching email from URL: #{e.message}"
  end

  def self.fetch_content_from_file(file_path)
    File.read(file_path)
  rescue Errno::ENOENT => e
    raise "Error reading email file: #{e.message}"
  rescue Errno::EACCES => e
    raise "Permission denied reading email file: #{e.message}"
  end

  def self.extract_json_attachment(mail)
    attachment = mail.attachments.find { |att| att.filename&.downcase&.end_with?('.json') }
    JSON.parse(attachment.body.decoded) if attachment
  rescue JSON::ParserError => e
    raise "Invalid JSON in attachment: #{e.message}"
  end

  def self.extract_first_json_link(body)
    links = extract_links(body, %w[http https])
    links.each do |link|
      cleaned_link = clean_link(link)
      json_data = fetch_json_from_link(cleaned_link)
      return json_data if json_data
    end
    nil
  end

  def self.extract_links(text, schemes = %w[http https])
    URI.extract(text, schemes)
  end

  def self.clean_link(link)
    link.gsub(/[)"'>]+$/, '')
  end

  def self.fetch_json_from_link(link)
    response = HTTParty.get(link)
    return parse_json(response.body) if json_response?(response)

    if html_response?(response)
      nested_link = extract_nested_json_link(response.body)
      return parse_json(HTTParty.get(nested_link).body) if nested_link && json_response?(HTTParty.get(nested_link))
    end

    nil
  rescue HTTParty::Error => e
    warn "HTTP error while fetching JSON from link #{link}: #{e.message}"
    nil
  rescue JSON::ParserError => e
    warn "JSON parsing error for link #{link}: #{e.message}"
    nil
  end

  def self.json_response?(response)
    response.headers['content-type']&.include?('application/json')
  end

  def self.html_response?(response)
    response.headers['content-type']&.include?('text/html')
  end

  def self.parse_json(body)
    JSON.parse(body)
  end

  def self.extract_nested_json_link(html_content)
    doc = Nokogiri::HTML(html_content)
    link = doc.at('a[href$=".json"]')&.[]('href')
    clean_link(link) if link
  end
end
