require 'spec-helper'

describe CommonDomain::Persistence::EventStore::StreamIO do
  let(:stream_opener) { mock(:stream_opener) }
  let(:stream) { mock(:stream) }
  let(:aggregate) { mock(:aggregate, aggregate_id: 'aggregate-239') }
  
  subject { Class.new do
    include CommonDomain::Persistence::EventStore::StreamIO
  end.new}
  
  describe "flush_changes" do
    before(:each) do
      stream_opener.stub(:open_stream) { stream }
      stream.stub(:add)
      aggregate.stub(:get_uncommitted_events) { [] }
      aggregate.stub(:clear_uncommitted_events)
    end
    it "should use stream_opener to get the stream, flush all the events into the stream and clear the aggregate" do
      evt1, evt2, evt3 = mock(:evt1), mock(:evt2), mock(:evt3)
      aggregate.should_receive(:get_uncommitted_events).and_return([evt1, evt2, evt3])
      stream.should_receive(:add).with(EventStore::EventMessage.new evt1)
      stream.should_receive(:add).with(EventStore::EventMessage.new evt2)
      stream.should_receive(:add).with(EventStore::EventMessage.new evt3)
      aggregate.should_receive(:clear_uncommitted_events)
      subject.flush_changes(aggregate, stream_opener).should be aggregate
    end
    
    it "should yield opened stream before clearing the aggregate if block given" do
      stream_yielded = false
      subject.flush_changes(aggregate, stream_opener) do |stream|
        aggregate.should_receive(:clear_uncommitted_events)
        stream_yielded = true
      end
      stream_yielded.should be_true
    end
  end
end