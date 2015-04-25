require 'spec-helper'

describe CommonDomain::Messages::MessagesHandler do
  class MessageOne; end
  module Messages
    class MessageTwo; end
  end
  class MessageThree; end  
  class UnhandledMessage; end
  
  let(:subject_class) {
    Class.new do
      include CommonDomain::Messages::MessagesHandler
    end
  }
  subject { subject_class.new }
  
  describe "can_handle_message?" do
    it "should return true if handler method is defined" do
      subject_class.send(:define_method, :'on_MessageOne_message') {}
      subject_class.send(:define_method, :'on_Messages_MessageTwo_message') {}
      expect(subject.can_handle_message?(MessageOne.new)).to be_truthy
      expect(subject.can_handle_message?(Messages::MessageTwo.new)).to be_truthy
    end
    
    it "should return false for unknown message" do
      expect(subject.can_handle_message?(UnhandledMessage.new)).to be_falsey
    end
  end
  
  describe "handle_message" do
    before(:each) do
      subject_class.class_eval do
        attr_reader :message_one_processed, :message_two_processed
        attr_reader :processed_message, :headers
        on MessageOne do |message|
          @processed_message = message
          @message_one_processed = true
        end
        on Messages::MessageTwo do |message|
          @processed_message = message
          @message_two_processed = true
        end
        on MessageThree do |message, headers|
          @processed_message = message
          @headers = headers
        end       
      end
    end
    
    it "should invoke corresponding handler in scope of handler instance" do
      message_one = MessageOne.new
      message_two = Messages::MessageTwo.new
      subject.handle_message message_one
      expect(subject.message_one_processed).to be_truthy
      expect(subject.processed_message).to be message_one
      
      subject.handle_message message_two
      expect(subject.message_two_processed).to be_truthy
      expect(subject.processed_message).to be message_two
    end
    
    it "should be able to handle messages handled by base class" do
      derived_class    = Class.new(subject_class)
      derived_instance = derived_class.new
      message_one = MessageOne.new
      message_two = Messages::MessageTwo.new
      expect(derived_instance.can_handle_message?(message_one)).to be_truthy
      expect(derived_instance.can_handle_message?(message_two)).to be_truthy
      derived_instance.handle_message message_one
      expect(derived_instance.message_one_processed).to be_truthy
      expect(derived_instance.processed_message).to be message_one
      
      derived_instance.handle_message message_two
      expect(derived_instance.message_two_processed).to be_truthy
      expect(derived_instance.processed_message).to be message_two
    end
    
    it "should raise error if no handler found" do
      expect(lambda { subject.handle_message UnhandledMessage.new }).to raise_error(CommonDomain::Messages::MessagesHandler::UnknownHandlerError)
    end

    it "should invoke corresponding handler with headers" do
      message = MessageThree.new
      subject.handle_message message, {header1: "header-1", header2: "header-2"}
      expect(subject.processed_message).to eql message
      expect(subject.headers).to eql({header1: "header-1", header2: "header-2"})
    end
  end
  
  describe "on" do
    it "should fail to register same handler twice" do
      subject_class.send(:on, MessageOne) { }
      expect(lambda { subject_class.send(:on, MessageOne) { } }).to raise_error(CommonDomain::Messages::MessagesHandler::HandlerAlreadyRegistered)
    end
    
    it "should define instance method for each message" do
      subject_class.class_eval do
        include CommonDomain::Messages::MessagesHandler
        on MessageOne do |event|
          
        end
        on Messages::MessageTwo do |event|
          
        end
      end
      expect(subject.respond_to?(:'on_MessageOne_message')).to be_truthy
      expect(subject.respond_to?(:'on_Messages_MessageTwo_message')).to be_truthy
    end
  end
  
  describe "on_any" do
    let(:block) { lambda { |event|  }}
    it "should perform on for each message class" do
      expect(subject_class).to receive(:on).with(MessageOne, &block)
      expect(subject_class).to receive(:on).with(Messages::MessageTwo, &block)
      subject_class.send(:on_any, MessageOne, Messages::MessageTwo, &block)
    end
    
    it "should perform on for each message class if messages are passed as a single arg array" do
      expect(subject_class).to receive(:on).with(MessageOne, &block)
      expect(subject_class).to receive(:on).with(Messages::MessageTwo, &block)
      subject_class.send(:on_any, [MessageOne, Messages::MessageTwo], &block)
    end
  end

  describe "message_handler_name" do
    it "should use underscores as namespaces delimiters" do
      expect(subject.send(:message_handler_name, MessageOne)).to eql :on_MessageOne_message
      expect(subject.send(:message_handler_name, Messages::MessageTwo)).to eql :on_Messages_MessageTwo_message
    end
  end
end
