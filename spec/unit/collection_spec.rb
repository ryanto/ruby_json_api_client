require 'spec_helper'

describe RubyJsonApiClient::Collection do
  let(:collection) { RubyJsonApiClient::Collection.new([1,2,3]) }

  subject { collection }

  its(:size) { should eq(3) }
  its(:first) { should eq(1) }

  context "mappable" do
    subject { collection.map(&:succ) }
    it { should have(3).elements }
    it { should include(2, 3, 4) }
  end

end
