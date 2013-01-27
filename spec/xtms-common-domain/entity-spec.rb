require 'spec-helper'

describe CommonDomain::Entity do
  let(:aggregate) { mock(:aggregate) }
  subject { described_class.new aggregate }
  
  it "should be a messages handler" do
    subject.should be_a CommonDomain::Infrastructure::MessagesHandler
  end
  
  describe "raise_event" do
    it "should delegate the event to the aggregate" do
      event = mock(:event)
      aggregate.should_receive(:raise_event).with(event)
      subject.send(:raise_event, event)
    end
  end
  
  describe "apply_event" do
    it "should just handle_message" do
      event = mock(:event)
      subject.should_receive(:handle_message).with(event)
      subject.apply_event event
    end
  end
end