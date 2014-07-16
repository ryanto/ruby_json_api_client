require 'spec_helper'

describe "AMS query records" do
  context "that are people" do

    before(:each) do
      RubyJsonApiClient::Store.register_adapter(:ams, {
        hostname: 'www.example.com'
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

    context "that exists" do
      before(:each) do
        response = {
          people: [{
            id: 123,
            firstname: 'ryan',
            lastname: 'test'
          },{
            id: 456,
            firstname: 'testing',
            lastname: 'again'
          }]
        }

        json = response.to_json

        stub_request(:get, "http://www.example.com/people?test=true")
          .to_return(
            status: 200,
            headers: { 'Content-Length' => json.size },
            body: json,
          )
      end

      let(:result) { Person.where(test: true) }
      subject { result }

      it { should have(2).people }

      context "verifying the first record" do
        subject { result[0] }
        its(:id) { should eq(123) }
        its(:full_name) { should eq('ryan test') }
      end

      context "verify the second record" do
        subject { result[1] }
        its(:id) { should eq(456) }
        its(:full_name) { should eq('testing again') }
      end

      context "and are mappable" do
        subject { result.map(&:firstname) }
        it { should have(2).first_names }
        it { should include('ryan') }
        it { should include('testing') }
      end
    end
  end
end
