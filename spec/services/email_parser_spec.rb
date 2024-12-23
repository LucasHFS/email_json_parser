require_relative '../../app/services/email_parser'

RSpec.describe EmailParser do
  describe '.extract_json' do
    let(:fixtures_path) { 'spec/fixtures' }

    context 'when email source is a file path' do
      context 'and email contains a JSON attachment' do
        it 'parses and returns the JSON content' do
          email_source = File.join(fixtures_path, 'email_with_json_attachment.eml')
          
          result = EmailParser.extract_json(email_source)
          expect(result).to eq({ 'key' => 'value' })
        end
      end
  
      context 'and email body contains a direct JSON link' do
        it 'fetches and returns the JSON from the link' do
          email_source = File.join(fixtures_path, 'email_with_json_link.eml')
          json_url = 'https://api.github.com/users/lucashfs/repos'
          stubbed_response = double(body: '{"key":"value"}', headers: { 'content-type' => 'application/json' })
  
          # Stub HTTParty.get for the JSON link
          allow(HTTParty).to receive(:get).with(json_url).and_return(stubbed_response)
  
          result = EmailParser.extract_json(email_source)
          expect(result).to eq({ 'key' => 'value' })
        end
      end
  
      context 'and email body contains a link to a page with a JSON link' do
        it 'fetches and returns the JSON from the nested link' do
          email_source = File.join(fixtures_path, 'email_with_nested_json_link.eml')
          page_url = 'https://example.com/page'
          nested_json_url = 'https://example.com/data.json'
  
          page_response = double(
            body: '<a href="https://example.com/data.json">JSON Link</a>',
            headers: { 'content-type' => 'text/html' }
          )
          json_response = double(
            body: '{"key":"value"}',
            headers: { 'content-type' => 'application/json' }
          )
  
          # Stub HTTParty.get for the initial page link and nested JSON link
          allow(HTTParty).to receive(:get).with(page_url).and_return(page_response)
          allow(HTTParty).to receive(:get).with(nested_json_url).and_return(json_response)
  
          result = EmailParser.extract_json(email_source)
          expect(result).to eq({ 'key' => 'value' })
        end
      end
  
      context 'and no JSON is found' do
        it 'returns nil' do
          email_source = File.join(fixtures_path, 'email_without_json.eml')
          
          # Ensure the fixture file exists
          expect(File.exist?(email_source)).to be true
  
          result = EmailParser.extract_json(email_source)
          expect(result).to be_nil
        end
      end
    end

    context 'when the email source is a URL' do
      context 'and email contains a JSON attachment' do
        it 'parses and returns the JSON content' do
          email_url = 'https://example.com/email_with_json_attachment.eml'
          email_content = File.read(File.join(fixtures_path, 'email_with_json_attachment.eml'))
          
          # Stub fetch_email_content to return the actual email content
          allow(EmailParser).to receive(:fetch_email_content).with(email_url).and_return(email_content)
  
          result = EmailParser.extract_json(email_url)
          expect(result).to eq({ 'key' => 'value' })
        end
      end
  
      context 'and email body contains a direct JSON link' do
        it 'fetches and returns the JSON from the link' do
          email_url = 'https://example.com/email_with_json_link.eml'
          email_content = File.read(File.join(fixtures_path, 'email_with_json_link.eml'))
          json_url = 'https://api.github.com/users/lucashfs/repos'
          stubbed_response = double(body: '{"key":"value"}', headers: { 'content-type' => 'application/json' })
  
          # Stub fetch_email_content to return the actual email content
          allow(EmailParser).to receive(:fetch_email_content).with(email_url).and_return(email_content)
          # Stub HTTParty.get for the JSON link
          allow(HTTParty).to receive(:get).with(json_url).and_return(stubbed_response)
  
          result = EmailParser.extract_json(email_url)
          expect(result).to eq({ 'key' => 'value' })
        end
      end
  
      context 'and email body contains a link to a page with a JSON link' do
        it 'fetches and returns the JSON from the nested link' do
          email_url = 'https://example.com/email_with_nested_json_link.eml'
          email_content = File.read(File.join(fixtures_path, 'email_with_nested_json_link.eml'))
          page_url = 'https://example.com/page'
          nested_json_url = 'https://example.com/data.json'
  
          page_response = double(
            body: '<a href="https://example.com/data.json">JSON Link</a>',
            headers: { 'content-type' => 'text/html' }
          )
          json_response = double(
            body: '{"key":"value"}',
            headers: { 'content-type' => 'application/json' }
          )
  
          # Stub fetch_email_content to return the actual email content
          allow(EmailParser).to receive(:fetch_email_content).with(email_url).and_return(email_content)
          # Stub HTTParty.get for the initial page link and nested JSON link
          allow(HTTParty).to receive(:get).with(page_url).and_return(page_response)
          allow(HTTParty).to receive(:get).with(nested_json_url).and_return(json_response)
  
          result = EmailParser.extract_json(email_url)
          expect(result).to eq({ 'key' => 'value' })
        end
      end
  
      context 'and no JSON is found' do
        it 'returns nil' do
          email_url = 'https://example.com/email_without_json.eml'
          email_content = File.read(File.join(fixtures_path, 'email_without_json.eml'))
          
          allow(EmailParser).to receive(:fetch_email_content).with(email_url).and_return(email_content)
  
          result = EmailParser.extract_json(email_url)
          expect(result).to be_nil
        end
      end
    end

    context 'when fetching email content from a URL fails' do
      it 'raises an appropriate error' do
        email_url = 'https://example.com/non_existent_email.eml'
        
        allow(EmailParser).to receive(:fetch_email_content).with(email_url).and_raise("Error fetching email from URL: 404 Not Found")

        expect {
          EmailParser.extract_json(email_url)
        }.to raise_error("Error fetching email from URL: 404 Not Found")
      end
    end

    context 'when fetching email content from a file fails' do
      it 'raises an appropriate error' do
        invalid_file_path = File.join(fixtures_path, 'non_existent_email.eml')
        
        allow(EmailParser).to receive(:fetch_email_content).with(invalid_file_path).and_raise("Error reading email file: No such file or directory @ rb_sysopen - #{invalid_file_path}")

        expect {
          EmailParser.extract_json(invalid_file_path)
        }.to raise_error("Error reading email file: No such file or directory @ rb_sysopen - #{invalid_file_path}")
      end
    end
  end
end
