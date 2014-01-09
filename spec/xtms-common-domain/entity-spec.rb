require 'spec-helper'

describe CommonDomain::Entity do
  let(:aggregate) { double(:aggregate, aggregate_id: 'aggregate-220') }
  subject { described_class.new aggregate }
  
  it "should be a messages handler" do
    subject.should be_a CommonDomain::Infrastructure::MessagesHandler
  end
  
  it "should have entity_id attribute initialized" do
    subject.entity_id.should be_nil
  end
  
  describe "initializer" do
    it "should assign aggregate and aggregate_id" do
      subject.aggregate.should be aggregate
      subject.aggregate_id.should eql 'aggregate-220'
    end
  end
  
  describe "raise_event" do
    it "should delegate the event to the aggregate" do
      event = double(:event)
      aggregate.should_receive(:raise_event).with(event)
      subject.send(:raise_event, event)
    end
  end
  
  describe "apply_event" do
    it "should just handle_message" do
      event = double(:event)
      subject.should_receive(:handle_message).with(event)
      subject.apply_event event
    end
  end
end