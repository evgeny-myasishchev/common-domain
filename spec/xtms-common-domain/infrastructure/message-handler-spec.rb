require 'spec-helper'

describe CommonDomain::Infrastructure::MessagesHandler do
  class MessageOne; end
  module Messages
    class MessageTwo; end
  end
  class UnhandledMessage; end
  
  let(:subject_class) {
    Class.new do
      include CommonDomain::Infrastructure::MessagesHandler
    end
  }
  subject { subject_class.new }
  
  describe "can_handle_message?" do
    it "should return true if handler method is defined" do
      subject_class.send(:define_method, :'on-MessageOne-message') {}
      subject_class.send(:define_method, :'on-Messages::MessageTwo-message') {}
      subject.can_handle_message?(MessageOne.new).should be_true
      subject.can_handle_message?(Messages::MessageTwo.new).should be_true
    end
    
    it "should return false for unknown message" do
      subject.can_handle_message?(UnhandledMessage.new).should be_false
    end
  end
  
  describe "handle_message" do
    before(:each) do
      subject_class.class_eval do
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
    end
    
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
    
    it "should be able to handle messages handled by base class" do
      derived_class    = Class.new(subject_class)
      derived_instance = derived_class.new
      message_one = MessageOne.new
      message_two = Messages::MessageTwo.new
      derived_instance.can_handle_message?(message_one).should be_true
      derived_instance.can_handle_message?(message_two).should be_true
      derived_instance.handle_message message_one
      derived_instance.message_one_processed.should be_true
      derived_instance.processed_message.should be message_one
      
      derived_instance.handle_message message_two
      derived_instance.message_two_processed.should be_true
      derived_instance.processed_message.should be message_two
    end
    
    it "should raise error if no handler found" do
      lambda { subject.handle_message UnhandledMessage.new }.should raise_error(CommonDomain::Infrastructure::MessagesHandler::UnknownHandlerError)
    end
  end
  
  describe "on" do
    it "should fail to register same handler twice" do
      subject_class.send(:on, MessageOne) { }
      lambda { subject_class.send(:on, MessageOne) { } }.should raise_error(CommonDomain::Infrastructure::MessagesHandler::HandlerAlreadyRegistered)
    end
    
    it "should define instance method for each message" do
      subject_class.class_eval do
        include CommonDomain::Infrastructure::MessagesHandler
        on MessageOne do |event|
          
        end
        on Messages::MessageTwo do |event|
          
        end
      end
      subject.respond_to?(:'on-MessageOne-message').should be_true
      subject.respond_to?(:'on-Messages::MessageTwo-message').should be_true
    end
  end
end
