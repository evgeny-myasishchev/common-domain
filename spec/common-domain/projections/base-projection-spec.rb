require 'spec-helper'

module CommonDomainProjectionsBaseSpec
  class DummyProjection
    include CommonDomain::Projections::Base
  end

  describe CommonDomain::Projections::Base do
    subject { DummyProjection.new }

    it "should be a MessagesHandler" do
      expect(subject).to be_a(CommonDomain::Messages::MessagesHandler)
    end
    
    it 'should maintain identifier based on the full class name' do
      expect(subject.identifier).to eql 'CommonDomainProjectionsBaseSpec::DummyProjection'
    end
  end
end