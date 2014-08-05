require 'spec_helper'

describe "JSON API find single" do
  context "person" do

    before(:each) do
      RubyJsonApiClient::Store.register_adapter(:json_api, {
        hostname: 'www.example.com'
      });

      RubyJsonApiClient::Store.register_serializer(:json_api)

      RubyJsonApiClient::Store.default(:json_api)
    end

    context "it exists" do
      before(:each) do
        response = {
          people: [{
            id: 123,
            firstname: 'ryan',
            lastname: 'test'
          }]
        }

        json = response.to_json

        stub_request(:get, "http://www.example.com/people/123")
          .to_return(
            status: 200,
            headers: { 'Content-Length' => json.size },
            body: json,
          )
      end

      context "loads the right model" do
        subject { Person.find(123) }
        its(:id) { should eq(123) }
        its(:firstname) { should eq("ryan") }
        its(:full_name) { should eq("ryan test") }
      end
    end
  end
end
