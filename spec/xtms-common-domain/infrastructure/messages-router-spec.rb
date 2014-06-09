require 'spec-helper'

describe CommonDomain::Infrastructure::MessagesRouter do
  subject { Class.new { include CommonDomain::Infrastructure::MessagesRouter }.new }
  
  describe "handlers?" do
    let(:handler) { double(:handler) }
    
    it "shold return true if there is at least one handler registered" do
      subject.register(handler)
      expect(subject.handlers?).to be_truthy
    end
    
    it "should return false if no handlers registered" do
      expect(subject.handlers?).to be_falsey
    end
  end
  
  describe "route" do
    it "should do nothing if no handlers registered" do
      subject.route(double(:message))
    end
    
    it "should route the message to each handler that can handle it" do
      message_one = double(:message_one)
      message_two = double(:message_two)
      
      handler_one = double(:handler_one)
      expect(handler_one).to receive(:can_handle_message?).with(message_one).and_return(true)
      expect(handler_one).to receive(:handle_message).with(message_one)
      expect(handler_one).to receive(:can_handle_message?).with(message_two).and_return(true)
      expect(handler_one).to receive(:handle_message).with(message_two)
      
      handler_two = double(:handler_one_two)
      expect(handler_two).to receive(:can_handle_message?).with(message_one).and_return(true)
      expect(handler_two).to receive(:handle_message).with(message_one)
      expect(handler_two).to receive(:can_handle_message?).with(message_two).and_return(true)
      expect(handler_two).to receive(:handle_message).with(message_two)
      
      subject.register handler_one
      subject.register handler_two
      
      subject.route message_one
      subject.route message_two
    end
    
    it "should not route message to handlers that can not handle it" do
      message_one = double(:message_one)
      message_two = double(:message_two)
      
      handler_one = double(:handler_one)
      expect(handler_one).to receive(:can_handle_message?).with(message_one).and_return(false)
      expect(handler_one).to receive(:can_handle_message?).with(message_two).and_return(false)
      
      subject.register handler_one
      
      subject.route message_one
      subject.route message_two
    end
    
    it "should return nil" do
      message_one = double(:message_one)
      handler_one = double(:handler_one, :can_handle_message? => true, :handle_message => "handler result")
      subject.register handler_one
      expect(subject.route(message_one)).to be_nil
    end
    
    it "should do nothing if there are no handlers for the msssage found" do
      subject.route(double(:message))
    end
    
    context "fail_if_no_handlers" do
      it "should fail if there are no handlers for the msssage found" do
        expect(lambda { subject.route(double(:message), fail_if_no_handlers: true) }).to raise_error(CommonDomain::Infrastructure::MessagesRouter::NoHandlersFound)
      end
    end
    
    context "ensure_single_handler" do
      it "should fail to route to several handlers" do
        message_one = double(:message_one)
        handler_one = double(:handler_one, :can_handle_message? => true)
        handler_two = double(:handler_two, :can_handle_message? => true)

        subject.register handler_one
        subject.register handler_two

        expect(lambda { subject.route(message_one, ensure_single_handler: true) }).to raise_error(CommonDomain::Infrastructure::MessagesRouter::SeveralHandlersFound)
      end
      
      it "should return handler result" do
        message_one = double(:message_one)
        handler_one = double(:handler_one, :can_handle_message? => true, :handle_message => "handler result")
        subject.register handler_one
        expect(subject.route(message_one, ensure_single_handler: true)).to eql "handler result"
      end
    end

    context "headers" do
      it "should route the message with headers" do
        headers = {header1: "header1", header2: "header2"}
        message = double(:message)

        handler_one = double(:handler_one, :can_handle_message? => true)
        expect(handler_one).to receive(:handle_message).with(message, headers)

        handler_two = double(:handler_two, :can_handle_message? => true)
        expect(handler_two).to receive(:handle_message).with(message, headers)

        subject.register handler_one
        subject.register handler_two

        subject.route message, headers: headers
      end
    end
  end
end
