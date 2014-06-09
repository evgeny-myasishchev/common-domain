require 'spec-helper'

describe CommonDomain::Command::DSL do
  subject {
    Class.new do
      include CommonDomain::Command::DSL
    end
  }
  
  describe "event" do
    before(:each) do
      subject.class_eval do
        command :CreateAccount, :login_name, :email_address
        command :RemoveAccount
      end
    end
    
    it "should define a new constant withing enclosed module" do
      expect(subject.const_defined?(:RemoveAccount)).to be_truthy
    end
    
    it "should inherit the constant from Command class" do
      expect(subject::RemoveAccount.superclass).to be CommonDomain::Command
    end
    
    it "should define reader attributes" do
      expect(subject::CreateAccount.method_defined?(:login_name)).to be_truthy
      expect(subject::CreateAccount.method_defined?(:email_address)).to be_truthy
    end
    
    it "should define initializer that initializes attributes" do
      instance = subject::CreateAccount.new "aggregate-100", :login_name => "some login name", :email_address => "some@email.com"
      expect(instance.aggregate_id).to eql "aggregate-100"
      expect(instance.login_name).to eql "some login name"
      expect(instance.email_address).to eql "some@email.com"
    end
    
    it "should be able to initialize if there are no attributes" do
      instance = subject::RemoveAccount.new "aggregate-100"
      expect(instance.aggregate_id).to eql "aggregate-100"
      
      instance = subject::RemoveAccount.new
      expect(instance.aggregate_id).to be_nil
    end
  end
  
  describe "commands_group" do
    subject {
      Module.new do
        include CommonDomain::Command::DSL
        
        commands_group :AccountCommands do
          command :CreateAccount
          command :RemoveAccount
        end
      end
    }
      
    it "should define a new module" do
      expect(subject.const_defined?(:AccountCommands)).to be_truthy
    end
    
    it "should include DSL in the module" do
      expect(subject::AccountCommands.included_modules).to include(CommonDomain::Command::DSL)
    end
    
    it "should eval passed block so events can be defined" do
      expect(subject::AccountCommands.const_defined?(:CreateAccount)).to be_truthy
      expect(subject::AccountCommands.const_defined?(:RemoveAccount)).to be_truthy
    end
  end
end