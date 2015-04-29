require 'spec-helper'

describe CommonDomain::Command::DSL do
  subject {
    Class.new do
      include CommonDomain::Command::DSL
    end
  }
  
  describe "command" do
    before(:each) do
      subject.class_eval do
        command :CreateAccount, :aggregate_id, :login_name, :email_address
        command :RemoveAccount, :aggregate_id
      end
    end
    
    it "should define a new constant withing enclosed module" do
      expect(subject.const_defined?(:RemoveAccount)).to be_truthy
    end
    
    it "should inherit the constant from Command class" do
      expect(subject::RemoveAccount.superclass).to be CommonDomain::Command
    end
    
    it "should define reader attributes" do
      expect(subject::CreateAccount.method_defined?(:aggregate_id)).to be_truthy
      expect(subject::CreateAccount.method_defined?(:login_name)).to be_truthy
      expect(subject::CreateAccount.method_defined?(:email_address)).to be_truthy
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