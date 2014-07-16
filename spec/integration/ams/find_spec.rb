require 'spec_helper'

describe "AMS find single" do
  context "person" do

    before(:each) do
      RubyJsonApiClient::Store.register_adapter(:ams, {
        hostname: 'www.example.com',
        namespace: 'testing',
        secure: true
      });

      RubyJsonApiClient::Store.register_serializer(:ams)

      RubyJsonApiClient::Store.default(:ams)
    end

    class Person < RubyJsonApiClient::Base
      field :firstname
      field :lastname

      def full_name
        "#{firstname} #{lastname}"
      end
    end

    context "it exists" do
      before(:each) do
        response = {
          person: {
            id: 123,
            firstname: 'ryan',
            lastname: 'test'
          }
        }

        json = response.to_json

        stub_request(:get, "https://www.example.com/testing/people/123")
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
