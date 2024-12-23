require_relative 'application_controller'

class EmailController < ApplicationController
  post '/parse_email' do
    email_source = params[:email_source]

    unless email_source && !email_source.strip.empty?
      halt_400_email_source_is_required
    end

    unless valid_email_source?(email_source)
      halt 400, { error: 'Email source must be a valid URL or existing file path' }.to_json
    end

    begin
      extracted_json = EmailParser.extract_json(email_source)

      if extracted_json
        status 200
        extracted_json.to_json
      else
        halt 404, { error: 'JSON not found in the email' }.to_json
      end
    rescue StandardError => e
      log_error(e)
      halt 500, { error: "An error occurred: #{e.message}" }.to_json
    end
  end

  private

  def halt_400_email_source_is_required
    halt 400, { error: 'Email source is required (URL or file path)' }.to_json
  end

  def log_error(error)
    logger.error("#{Time.now} - Error: #{error.message}")
  end

  def valid_email_source?(source)
    uri = URI.parse(source)
    uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS) || File.exist?(source)
  rescue URI::InvalidURIError
    File.exist?(source)
  end
end
