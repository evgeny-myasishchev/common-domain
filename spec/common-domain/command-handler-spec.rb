require 'spec-helper'

describe CommonDomain::CommandHandler do
  module Messages
    class Dummy
      attr_accessor :headers
    end
    class Dummy1
      attr_accessor :headers
    end
  end
  let(:repository) { double(:repository) }
  subject { Class.new(CommonDomain::CommandHandler) do
    
  end.new(repository)}
  
  it "should be a kind of a MessagesHandler" do
    expect(CommonDomain::CommandHandler.new).to be_a_kind_of CommonDomain::Infrastructure::MessagesHandler
  end
  
  it "should handle messages" do
    expected = Messages::Dummy.new
    actual = nil
    subject.class.class_eval do
      on(Messages::Dummy) { |message| actual = message }
    end
    subject.handle_message expected
    expect(actual).to be expected
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
    expect(actual_message).to be expected
    expect(actual_headers).to be expected_headers
  end
  
  it "should be possible to define message handlers that will be wrapped into begin_work" do
    work = double(:work)
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
    expect(repository).to receive(:begin_work).twice do |&block|
      block.call(work)
    end

    subject.handle_message msg1
    expect(actual_args).to eql({work: work, message: msg1})
    
    subject.handle_message msg2, headers
    expect(actual_args).to eql({work: work, message: msg2, headers: headers})
  end
  
  it "should begin_work with headers" do
    subject.class.class_eval do
      on Messages::Dummy, begin_work: true do |work, message|
      end
    end
    message = Messages::Dummy.new
    message.headers = {header: 'header-1'}
    expect(repository).to receive(:begin_work).with(message.headers) do |&block|
      block.call(double(:work))
    end
    subject.handle_message(message)
  end

  it "should return message result for wrapped methods" do
    subject.class.class_eval do
      on Messages::Dummy, begin_work: true do |work, message|
        return "Dummy result"
      end
    end
    expect(repository).to receive(:begin_work) do |&block|
      block.call(double(:work))
    end
    expect(subject.handle_message(Messages::Dummy.new)).to eql "Dummy result"
  end
  
  it "should raise ArgumentError if handler block has wrong number of args" do
    expect(repository).to begin_work
    subject.class.class_eval do
      on(Messages::Dummy, begin_work: true) { |message| }
    end
    expect{subject.handle_message(Messages::Dummy.new)}.to raise_error ArgumentError, 'Messages::Dummy handler block should have 2 or 3 arguments: work, command and optionally headers. Got: 1.'
  end
end