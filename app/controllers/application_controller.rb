# frozen_string_literal: true

require 'sinatra/base'
require 'json'
require 'logger'

class ApplicationController < Sinatra::Base
  configure do
    set :show_exceptions, false
    set :logger, Logger.new($stdout)
  end

  before do
    content_type :json

    if request.content_length&.to_i&.> 10_000
      halt 413, { error: 'Request body too large' }.to_json
    end

    if request.content_type == 'application/json'
      begin
        request.body.rewind
        body = request.body.read
        parsed_body = JSON.parse(body)
        params.merge!(parsed_body) unless parsed_body.nil?
      rescue JSON::ParserError => e
        logger.error("JSON Parsing Error: #{e.message}")
        halt 400, { error: 'Invalid JSON format in request body' }.to_json
      end
    end
  end

  error JSON::ParserError do
    logger.error("JSON Parsing Error: #{env['sinatra.error'].message}")
    halt 400, { error: 'Invalid JSON format in request body' }.to_json
  end

  error do
    error = env['sinatra.error']
    logger.error("Internal Server Error: #{error.message}")
    halt 500, { error: "An internal error occurred: #{error.message}" }.to_json
  end
end
