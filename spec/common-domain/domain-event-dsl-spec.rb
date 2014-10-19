require 'spec-helper'

describe CommonDomain::DomainEvent::DSL do
  subject {
    Class.new do
      include CommonDomain::DomainEvent::DSL
    end
  }
  
  describe "event" do
    before(:each) do
      subject.class_eval do
        event :AccountCreated, :login_name, :email_address
        event :AccountRemoved
      end
    end
    
    it "should define a new constant withing enclosed module" do
      expect(subject.const_defined?(:AccountRemoved)).to be_truthy
    end
    
    it "should inherit the constant from DomainEvent class" do
      expect(subject::AccountRemoved.superclass).to be CommonDomain::DomainEvent
    end
    
    it "should define reader attributes" do
      expect(subject::AccountCreated.method_defined?(:login_name)).to be_truthy
      expect(subject::AccountCreated.method_defined?(:email_address)).to be_truthy
    end
    
    it "should define initializer that initializes attributes" do
      instance = subject::AccountCreated.new "aggregate-100", "some login name", "some@email.com"
      expect(instance.aggregate_id).to eql "aggregate-100"
      expect(instance.login_name).to eql "some login name"
      expect(instance.email_address).to eql "some@email.com"
    end
    
    it "should be able to initialize if there are no attributes" do
      instance = subject::AccountRemoved.new "aggregate-100"
      expect(instance.aggregate_id).to eql "aggregate-100"
    end
    
    it "should fail to initialize if number of attributes is different than declared" do
      expect(lambda { subject::AccountCreated.new "aggregate-100" }).to raise_error("Failed to instantiate the event. Expected 3 arguments, got 1")
      expect(lambda { subject::AccountCreated.new "aggregate-100", 'hello' }).to raise_error("Failed to instantiate the event. Expected 3 arguments, got 2")
    end
  end
  
  describe "events_group" do
    subject {
      Module.new do
        include CommonDomain::DomainEvent::DSL
        
        events_group :AccountEvents do
          event :AccountCreated
          event :AccountRemoved
        end
      end
    }
    
    it "should define a new module" do
      expect(subject.const_defined?(:AccountEvents)).to be_truthy
    end
    
    it "should include DSL in the module" do
      expect(subject::AccountEvents.included_modules).to include(CommonDomain::DomainEvent::DSL)
    end
    
    it "should eval passed block so events can be defined" do
      expect(subject::AccountEvents.const_defined?(:AccountCreated)).to be_truthy
      expect(subject::AccountEvents.const_defined?(:AccountRemoved)).to be_truthy
    end
  end
end