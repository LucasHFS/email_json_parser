# frozen_string_literal: true

require 'json'
require_relative '../../app'

RSpec.describe EmailController do
  let(:fixtures_path) { 'spec/fixtures' }

  def app
    Sinatra::Application
  end

  describe 'POST /parse_email' do
    subject do
      post '/parse_email', request_body, { 'CONTENT_TYPE' => 'application/json' }
      last_response
    end

    let(:request_body) { { email_source: email_source }.to_json }

    context 'when email_source is provided' do
      let(:email_source) { File.join(fixtures_path, 'email_with_json_attachment.eml') }

      it 'returns the parsed JSON if found' do
        allow(EmailParser).to receive(:extract_json).with(email_source).and_return({ 'key' => 'value' })

        expect(subject.status).to eq(200)
        expect(JSON.parse(subject.body)).to eq(
          'key' => 'value'
        )
      end

      it 'returns 404 if JSON is not found' do
        allow(EmailParser).to receive(:extract_json).with(email_source).and_return(nil)

        expect(subject.status).to eq(404)
        expect(JSON.parse(subject.body)).to eq(
          'error' => 'JSON not found in the email'
        )
      end
    end

    context 'when email_source is missing' do
      let(:request_body) { {}.to_json }

      it 'returns 400 with an error message' do
        post '/parse_email'

        expect(subject.status).to eq(400)
        expect(JSON.parse(subject.body)).to eq(
          'error' => 'Email source is required (URL or file path)'
        )
      end
    end

    context 'when an exception occurs' do
      let(:email_source) { File.join(fixtures_path, 'email_with_json_attachment.eml') }

      it 'returns 500 with an error message' do
        allow(EmailParser).to receive(:extract_json).with(email_source).and_raise(StandardError.new('Something went wrong'))

        post '/parse_email', email_source: email_source

        expect(subject.status).to eq(500)
        expect(JSON.parse(subject.body)).to eq(
          'error' => 'An error occurred: Something went wrong'
        )
      end
    end
  end
end
