require 'spec_helper'

describe RubyJsonApiClient::RestAdapter do
  let(:adapter) do
    RubyJsonApiClient::RestAdapter.new(
      hostname: 'www.example.com',
      namespace: 'testing',
      secure: true
    )
  end

  describe :initialize do
    subject { adapter }
    its(:hostname) { should eq('www.example.com') }
    its(:secure) { should eq(true) }
    its(:namespace) { should eq('testing') }
  end

  describe :single_path do
    context Person do
      subject { adapter.single_path(Person, { id: 1 }) }
      it { should == "testing/people/1" }
    end

    context Thing do
      subject { adapter.single_path(Thing, { id: 2 }) }
      it { should == "testing/things/2" }
    end

    context CellPhone do
      subject { adapter.single_path(CellPhone, { id: 3 }) }
      it { should == "testing/cell_phones/3" }
    end
  end

  describe :collection_path do
    context Person do
      subject { adapter.collection_path(Person, {}) }
      it { should == "testing/people" }
    end

    context Thing do
      subject { adapter.collection_path(Thing, {}) }
      it { should == "testing/things" }
    end

    context CellPhone do
      subject { adapter.collection_path(CellPhone, {}) }
      it { should == "testing/cell_phones" }
    end
  end

  describe :find do
    let(:person) { Person.new }

    it "should make the right http request" do
      status = 200
      headers = {}
      body = "{}"

      expect(adapter).to receive(:http_request)
        .with(:get, "testing/people/1", {})
        .and_return([status, headers, body])

      expect(adapter.find(Person, 1)).to eq(body)
    end

    it "should raise an error if the status is 500" do
      status = 500
      headers = {}
      body = "{}"

      expect(adapter).to receive(:http_request)
        .with(:get, "testing/people/1", {})
        .and_return([status, headers, body])

      expect { adapter.find(Person, 1) }.to raise_error
    end
  end

  describe :find_many do
    let(:person) { Person.new }
    let(:people) { [person, person] }

    it "should make the right http request" do
      status = 200
      headers = {}
      body = "{}"

      expect(adapter).to receive(:http_request)
        .with(:get, "testing/people", { sort: :asc })
        .and_return([status, headers, body])

      expect(adapter.find_many(Person, sort: :asc)).to eq(body)
    end

    it "should error if the status is 500" do
      status = 500
      headers = {}
      body = "{}"

      expect(adapter).to receive(:http_request)
        .with(:get, "testing/people", { sort: :asc })
        .and_return([status, headers, body])

      expect { adapter.find_many(Person, sort: :asc) }.to raise_error
    end
  end
end
