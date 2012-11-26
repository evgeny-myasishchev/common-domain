require 'spec-helper'

describe CommonDomain::CommandHandler do
  module Messages
    class Dummy
    end
    class Dummy1
    end
  end
  let(:repository) { mock(:repository) }
  subject { Class.new(CommonDomain::CommandHandler) do
    
  end.new(repository)}
  
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
  
  it "should be possible to define message handlers that will be wrapped into begin_work" do
    work = mock(:work)
    msg1 = Messages::Dummy.new
    msg2 = Messages::Dummy1.new
    headers = { header: 'header-1'}
    actual_args = {}
    subject.class.class_eval do
      on Messages::Dummy, begin_work: true do |work, message|
        actual_args = {work: work, message: message}
      end
      
      on Messages::Dummy1, begin_work: true do |work, message, headers|
        actual_args = {work: work, message: message, headers: headers}
      end
    end
    repository.should_receive(:begin_work).twice do |&block|
      block.call(work)
    end

    subject.handle_message msg1
    actual_args.should eql({work: work, message: msg1})
    
    subject.handle_message msg2, headers
    actual_args.should eql({work: work, message: msg2, headers: headers})
  end
  
  it "should return message result for wrapped methods" do
    subject.class.class_eval do
      on Messages::Dummy, begin_work: true do |work, message|
        return "Dummy result"
      end
    end
    repository.should_receive(:begin_work) do |&block|
      block.call(mock(:work))
    end
    subject.handle_message(Messages::Dummy.new).should eql "Dummy result"
  end
end