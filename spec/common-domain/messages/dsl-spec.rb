require 'spec-helper'

module CommonDomainMessagesDslSpec
  module Messages
    include CommonDomain::Messages::Dsl
    message :NoAttributesMessage
    message :SimpleMessage, :login, :password
  end
  
  describe CommonDomain::Messages::Dsl do
    describe 'message' do
      it 'should define message without any attribute' do
        expect(Messages.const_defined?(:NoAttributesMessage)).to be_truthy
        expect(Messages::NoAttributesMessage.new).to be_a CommonDomain::Messages::Message
        expect(Messages::NoAttributesMessage.attribute_names).to be_empty
      end
      
      it 'should define simple message with provided attributes' do
        expect(Messages.const_defined?(:SimpleMessage)).to be_truthy
        expect(Messages::SimpleMessage.new({})).to be_a CommonDomain::Messages::Message
        expect(Messages::SimpleMessage.attribute_names).to eql [:login, :password]
      end
    end
  end
end