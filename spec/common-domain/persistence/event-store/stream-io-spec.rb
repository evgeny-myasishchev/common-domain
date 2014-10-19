require 'spec-helper'

describe CommonDomain::Persistence::EventStore::StreamIO do
  let(:stream_opener) { double(:stream_opener) }
  let(:stream) { double(:stream) }
  let(:aggregate) { double(:aggregate, aggregate_id: 'aggregate-239') }
  
  subject { Class.new do
    include CommonDomain::Persistence::EventStore::StreamIO
  end.new}
  
  describe "flush_changes" do
    before(:each) do
      allow(stream_opener).to receive(:open_stream) { stream }
      allow(stream).to receive(:add)
      allow(aggregate).to receive(:get_uncommitted_events) { [] }
      allow(aggregate).to receive(:clear_uncommitted_events)
    end
    it "should use stream_opener to get the stream, flush all the events into the stream and clear the aggregate" do
      evt1, evt2, evt3 = double(:evt1), double(:evt2), double(:evt3)
      expect(aggregate).to receive(:get_uncommitted_events).and_return([evt1, evt2, evt3])
      expect(stream).to receive(:add).with(EventStore::EventMessage.new evt1)
      expect(stream).to receive(:add).with(EventStore::EventMessage.new evt2)
      expect(stream).to receive(:add).with(EventStore::EventMessage.new evt3)
      expect(aggregate).to receive(:clear_uncommitted_events)
      expect(subject.flush_changes(aggregate, stream_opener)).to be aggregate
    end
    
    it "should yield opened stream before clearing the aggregate if block given" do
      stream_yielded = false
      subject.flush_changes(aggregate, stream_opener) do |stream|
        expect(aggregate).to receive(:clear_uncommitted_events)
        stream_yielded = true
      end
      expect(stream_yielded).to be_truthy
    end
  end
end