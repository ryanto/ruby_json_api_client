require 'spec_helper'

describe RubyJsonApiClient do
  let(:serializer) { RubyJsonApiClient::JsonApiSerializer.new }

  describe :transform do
    let(:json) { "{\"testing\":true, \"firstname\":\"ryan\"}" }
    subject { serializer.transform(json)["testing"] }
    it { should eql(true) }
  end

  describe :extract_single do
    context "will error when" do
      subject { ->{ serializer.extract_single(Person, 1, json) } }

      context "no json root key exists" do
        let(:json) { "{\"firstname\":\"ryan\"}" }
        it { should raise_error }
      end

      context "single resource is not a collection" do
        let(:json) { "{ \"people\": { \"firstname\":\"ryan\" } }" }
        it { should raise_error }
      end

      context "no id" do
        let(:json) { "{\"people\": [{ \"firstname\":\"ryan\" }] }" }
        it { should raise_error }
      end

      context "the id returned is not the id we are looking for" do
        let(:json) { "{\"people\": [{ \"id\": 2, \"firstname\":\"ryan\" }] }" }
        it { should raise_error }
      end
    end

    context "when payload contains" do
      subject { serializer.extract_single(Person, 1, json) }

      context "string ids" do
        let(:json) { "{\"people\": [{ \"id\": \"1\", \"firstname\":\"ryan\" }] }" }
        it { should be_instance_of(Person) }
      end

      context "attributes that are defined" do
        let(:json) { "{\"people\": [{ \"id\": \"1\", \"firstname\":\"ryan\" }] }" }
        let(:model) { subject }

        it { should be_instance_of(Person) }
        it { should respond_to(:firstname) }

        it "should set the right values" do
          expect(model.firstname).to eq('ryan')
        end
      end

      context "attributes that are not defined" do
        let(:json) { "{\"people\": [{ \"id\": \"1\", \"unknown\":\"ryan\" }] }" }
        it { should be_instance_of(Person) }
        it { should_not respond_to(:unknown) }
      end
    end

    context "using multi worded models" do
      subject { serializer.extract_single(CellPhone, 1, json) }
      let(:model) { subject }

      class CellPhone < RubyJsonApiClient::Base
        field :number
      end

      let(:json) { "{\"cell_phones\": [{ \"id\": 1, \"number\": \"123-456-7890\" }] }" }
      it { should be_instance_of(CellPhone) }

      it "should set the right number" do
        expect(model.number).to eq('123-456-7890')
      end
    end
  end

  describe :extract_many do
    context "will error when" do
      subject { ->{ serializer.extract_many(Person, json) } }

      context "there is no plural key in the response" do
        let(:json) { "[{ \"id\": 1, \"firstname\": \"ryan\" }]" }
        it { should raise_error }
      end

      context "there is no array of data" do
        let(:json) { "{ \"id\": 1, \"firstname\": \"ryan\" }" }
        it { should raise_error }
      end
    end

    context "when payload contains" do
      subject { serializer.extract_many(Person, json) }
      let(:collection) { subject }

      context "multiple records" do
        let(:json) do
          "{ \"people\": [{ \"id\": 1, \"firstname\": \"ryan\" }, { \"id\": 2, \"firstname\": \"ryan2\" }] }"
        end

        it { should have(2).items }

        it "should serialize one of the records" do
          expect(collection.first).to respond_to(:firstname)
          expect(collection.first.firstname).to eq('ryan')
        end
      end
    end
  end
end
