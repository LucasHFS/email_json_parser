require 'sinatra'
require_relative '../services/email_parser'

class EmailController < Sinatra::Base
  before do
    content_type :json
  end

  post '/parse_email' do
    request_body = request.body.read 
    halt_400_email_source_is_required if request_body.empty?
    
    parsed_body = JSON.parse(request_body)
  
    email_source = parsed_body['email_source']
    halt_400_email_source_is_required unless email_source

    result = parse_email_source(email_source)
    status result[:status]
    result[:body].to_json
  end

  private

  def halt_400_email_source_is_required
    halt 400, { error: 'Email source is required (URL or file path)' }.to_json
  end

  def parse_email_source(email_source)
    extracted_json = EmailParser.extract_json(email_source)

    if extracted_json
      { status: 200, body: extracted_json}
    else
      { status: 404, body: { error: 'JSON not found in the email' } }
    end
  rescue StandardError => e
    { status: 500, body: { error: "An error occurred: #{e.message}" } }
  end
end
