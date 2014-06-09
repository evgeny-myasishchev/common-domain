require 'spec-helper'

describe CommonDomain::Entity do
  let(:aggregate) { double(:aggregate, aggregate_id: 'aggregate-220') }
  subject { described_class.new aggregate }
  
  it "should be a messages handler" do
    expect(subject).to be_a CommonDomain::Infrastructure::MessagesHandler
  end
  
  it "should have entity_id attribute initialized" do
    expect(subject.entity_id).to be_nil
  end
  
  describe "initializer" do
    it "should assign aggregate and aggregate_id" do
      expect(subject.aggregate).to be aggregate
      expect(subject.aggregate_id).to eql 'aggregate-220'
    end
  end
  
  describe "raise_event" do
    it "should delegate the event to the aggregate" do
      event = double(:event)
      expect(aggregate).to receive(:raise_event).with(event)
      subject.send(:raise_event, event)
    end
  end
  
  describe "apply_event" do
    it "should just handle_message" do
      event = double(:event)
      expect(subject).to receive(:handle_message).with(event)
      subject.apply_event event
    end
  end
end