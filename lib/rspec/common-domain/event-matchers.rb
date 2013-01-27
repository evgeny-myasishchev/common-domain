RSpec::Matchers.define :have_one_uncommitted_event do |event_type, attribs|
  match do |actual|
    -> {
      return false unless actual.get_uncommitted_events.length == 1
      event = actual.get_uncommitted_events[0]
      return false unless event.instance_of?(event_type)
      attribs.each_key do |attrib|
        return false unless event.send(attrib) == attribs[attrib]
      end
      return true
    }.call
  end

  failure_message_for_should do |actual|
    -> {
      event_type    = expected[0]
      attribs       = expected[1]
      
      events_length = actual.get_uncommitted_events.length
      return %(expected: aggregate "#{actual}" has 1 uncommitted event\ngot: #{events_length}) unless events_length == 1
      
      event = actual.get_uncommitted_events[0]
      return %(expected that the event to be an instance of #{event_type} but got #{event.class}) unless event.instance_of?(event_type)
      
      attribs.each_key do |attrib|
        expected_value = attribs[attrib]
        actual_value   = event.send(attrib)
        return %(expected: attribute "#{attrib}" to equal "#{expected_value}"\ngot: "#{actual_value}") unless expected_value == actual_value
      end
      nil
    }.call
  end
end


RSpec::Matchers.define :have_uncommitted_events do
  match do |actual|
    actual.get_uncommitted_events.length != 0
  end
  
  failure_message_for_should do |actual|
    %(expected that an aggregate "#{actual}" has uncommitted events.)
  end
  
  failure_message_for_should_not do |actual|
    %(expected that an aggregate "#{actual}" has no uncommitted events\ngot: #{actual.get_uncommitted_events.length})
  end
end


RSpec::Matchers.define :raise_event do |event|
  match do |aggregate|
    aggregate.should_receive(:raise_event).with(event)
  end
end