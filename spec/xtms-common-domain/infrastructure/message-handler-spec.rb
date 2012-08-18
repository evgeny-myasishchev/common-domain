require 'spec-helper'

describe CommonDomain::Infrastructure::MessagesHandler do
  class MessageOne; end
  module Messages
    class MessageTwo; end
  end
  class UnhandledMessage; end
  
  class Handler
    include CommonDomain::Infrastructure::MessagesHandler
    attr_reader :message_one_processed, :message_two_processed
    attr_reader :processed_message
    on MessageOne do |message|
      @processed_message = message
      @message_one_processed = true
    end
    on Messages::MessageTwo do |message|
      @processed_message = message
      @message_two_processed = true
    end
  end
  
  subject { Handler.new }
  
  describe "registered_message_handlers" do
    it "should return an array of message classes that handled" do
      subject.registered_message_handlers.should have(2).items
      subject.registered_message_handlers.should include(MessageOne)
      subject.registered_message_handlers.should include(Messages::MessageTwo)
    end
  end
  
  describe "can_handle_message?" do
    it "should return true if handler is defined" do
      subject.can_handle_message?(MessageOne.new).should be_true
      subject.can_handle_message?(Messages::MessageTwo.new).should be_true
    end
    
    it "should return false for unknown message" do
      subject.can_handle_message?(UnhandledMessage.new).should be_false
    end
  end
  
  describe "handle_message" do
    it "should invoke corresponding handler in scope of handler instance" do
      message_one = MessageOne.new
      message_two = Messages::MessageTwo.new
      subject.handle_message message_one
      subject.message_one_processed.should be_true
      subject.processed_message.should be message_one
      
      subject.handle_message message_two
      subject.message_two_processed.should be_true
      subject.processed_message.should be message_two
    end
    
    it "should raise error if no handler found" do
      lambda { subject.handle_message UnhandledMessage.new }.should raise_error(CommonDomain::Infrastructure::MessagesHandler::UnknownHandlerError)
    end
  end
  
  describe "on" do
    it "should fail to register same handler twice" do
      lambda { Handler.send(:on, MessageOne) }.should raise_error(CommonDomain::Infrastructure::MessagesHandler::HandlerAlreadyRegistered)
    end
    
    it "should register same message in different classes" do
      class_one = Class.new do
        include CommonDomain::Infrastructure::MessagesHandler
        on MessageOne do |message|
        end
      end
      class_two = Class.new do
        include CommonDomain::Infrastructure::MessagesHandler
        on MessageOne do |message|
        end
        on Messages::MessageTwo do |message|
        end
      end
      instance_one = class_one.new
      instance_one.registered_message_handlers.should have(1).items
      instance_one.registered_message_handlers.should include(MessageOne)
      
      instance_two = class_two.new
      instance_two.registered_message_handlers.should have(2).items
      instance_two.registered_message_handlers.should include(MessageOne)
      instance_two.registered_message_handlers.should include(Messages::MessageTwo)
    end
  end
end