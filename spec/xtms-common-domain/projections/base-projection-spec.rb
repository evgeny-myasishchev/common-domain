require 'spec-helper'

describe CommonDomain::Projections::Base do
  let(:described_class) {  
    Class.new do
      include CommonDomain::Projections::Base
    end
  }
  
  it "should be a MessagesHandler" do
    expect(subject).to be_a(CommonDomain::Infrastructure::MessagesHandler)
  end
end
