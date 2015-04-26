require 'spec-helper'

module CommonDomainMessagesDSLSpec
  module Messages
    include CommonDomain::Messages::DSL
    message :NoAttributesMessage
    message :SimpleMessage, :login, :password
    
    group :TheGroup do
      message :GroupMessage
    end
  end
  
  describe CommonDomain::Messages::DSL do
    describe 'message' do
      it 'should define message without any attribute' do
        expect(Messages.const_defined?(:NoAttributesMessage)).to be_truthy
        expect(Messages::NoAttributesMessage.new).to be_a CommonDomain::Messages::Message
        expect(Messages::NoAttributesMessage.attribute_names).to be_empty
      end
      
      it 'should define simple message with provided attributes' do
        expect(Messages.const_defined?(:SimpleMessage)).to be_truthy
        expect(Messages::SimpleMessage.new(login: 'test', password: 'password')).to be_a CommonDomain::Messages::Message
        expect(Messages::SimpleMessage.attribute_names).to eql [:login, :password]
      end
    end
    
    describe 'group' do
      it 'should define nested module' do
        expect(Messages.const_defined?(:TheGroup)).to be_truthy
        expect(Messages::TheGroup.class).to eql Module
        expect(Messages::TheGroup::GroupMessage.superclass).to eql CommonDomain::Messages::Message
      end
    end
  end
end