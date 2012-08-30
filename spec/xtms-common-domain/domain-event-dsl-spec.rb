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
      subject.const_defined?(:AccountRemoved).should be_true
    end
    
    it "should inherit the constant from DomainEvent class" do
      subject::AccountRemoved.superclass.should be CommonDomain::DomainEvent
    end
    
    it "should define reader attributes" do
      subject::AccountCreated.method_defined?(:login_name).should be_true
      subject::AccountCreated.method_defined?(:email_address).should be_true
    end
    
    it "should define initializer that initializes attributes" do
      instance = subject::AccountCreated.new "aggregate-100", "some login name", "some@email.com"
      instance.aggregate_id.should eql "aggregate-100"
      instance.login_name.should eql "some login name"
      instance.email_address.should eql "some@email.com"
    end
    
    it "should be able to initialize if there are no attributes" do
      instance = subject::AccountRemoved.new "aggregate-100"
      instance.aggregate_id.should eql "aggregate-100"
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
      subject.const_defined?(:AccountEvents).should be_true
    end
    
    it "should include DSL in the module" do
      subject::AccountEvents.included_modules.should include(CommonDomain::DomainEvent::DSL)
    end
    
    it "should eval passed block so events can be defined" do
      subject::AccountEvents.const_defined?(:AccountCreated).should be_true
      subject::AccountEvents.const_defined?(:AccountRemoved).should be_true
    end
  end
end