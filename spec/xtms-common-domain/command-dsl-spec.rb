require 'spec-helper'

describe CommonDomain::Command::DSL do
  subject {
    Class.new do
      include CommonDomain::Command::DSL
    end
  }
  
  describe "domain_event" do
    before(:each) do
      subject.class_eval do
        command :CreateAccount, :login_name, :email_address
        command :RemoveAccount
      end
    end
    
    it "should define a new constant withing enclosed module" do
      subject.const_defined?(:RemoveAccount).should be_true
    end
    
    it "should inherit the constant from Command class" do
      subject::RemoveAccount.superclass.should be CommonDomain::Command
    end
    
    it "should define reader attributes" do
      subject::CreateAccount.method_defined?(:login_name).should be_true
      subject::CreateAccount.method_defined?(:email_address).should be_true
    end
    
    it "should define initializer that initializes attributes" do
      instance = subject::CreateAccount.new "aggregate-100", :login_name => "some login name", :email_address => "some@email.com"
      instance.aggregate_id.should eql "aggregate-100"
      instance.login_name.should eql "some login name"
      instance.email_address.should eql "some@email.com"
    end
    
    it "should be able to initialize if there are no attributes" do
      instance = subject::RemoveAccount.new "aggregate-100"
      instance.aggregate_id.should eql "aggregate-100"
      
      instance = subject::RemoveAccount.new
      instance.aggregate_id.should be_nil
    end
  end
end