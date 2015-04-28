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
        event :AccountCreated
      end
    end
    
    it "should inherit the constant from DomainEvent class" do
      expect(subject::AccountCreated.superclass).to be CommonDomain::DomainEvent
    end
  end
  
  describe "events_group" do
    subject {
      Module.new do
        include CommonDomain::DomainEvent::DSL
        
        events_group :AccountEvents do
          event :AccountCreated
        end
      end
    }
    
    it "should include DSL in the module" do
      expect(subject::AccountEvents.included_modules).to include(CommonDomain::DomainEvent::DSL)
      expect(subject::AccountEvents.const_defined?(:AccountCreated)).to be_truthy
      expect(subject::AccountEvents::AccountCreated.superclass).to be CommonDomain::DomainEvent

    end
  end
end