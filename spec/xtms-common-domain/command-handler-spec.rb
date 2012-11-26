require 'spec-helper'

describe CommonDomain::CommandHandler do
  module Messages
    class Dummy
    end
  end
  
  subject { Class.new(CommonDomain::CommandHandler) do
    
  end.new}
  
  it "should be a kind of a MessagesHandler" do
    CommonDomain::CommandHandler.new.should be_a_kind_of CommonDomain::Infrastructure::MessagesHandler
  end
  
  it "should handle messages" do
    expected = Messages::Dummy.new
    actual = nil
    subject.class.class_eval do
      on(Messages::Dummy) { |message| actual = message }
    end
    subject.handle_message expected
    actual.should be expected
  end
  
  it "should also handle messages with headers" do
    expected = Messages::Dummy.new
    expected_headers = { header: 'header-1'}
    actual_message = nil
    actual_headers = nil
    subject.class.class_eval do
      on(Messages::Dummy) { |message, headers| actual_message, actual_headers = message, headers }
    end
    subject.handle_message expected, expected_headers
    actual_message.should be expected
    actual_headers.should be expected_headers
  end
  
  it "should be possible to define message handlers that will be wrapped into begin_work"
end