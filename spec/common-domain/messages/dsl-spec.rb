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
  
  module ConfiguredMessages
    class CustomMessagesClass
    end
    
    module DSL
      def self.included(receiver)
        receiver.include CommonDomain::Messages::DSL
        receiver.setup_dsl message_base_class: CustomMessagesClass, dsl_module: CommonDomainMessagesDSLSpec::ConfiguredMessages::DSL
      end
    end
    
    include CommonDomainMessagesDSLSpec::ConfiguredMessages::DSL
    
    message :CustomSimpleMessage
    group :CustomGroup do
      message :ConfiguredSimpleGroupMessage
    end
  end
  
  describe CommonDomain::Messages::DSL do
    describe 'message' do
      it 'should define message without any attribute' do
        expect(Messages.const_defined?(:NoAttributesMessage)).to be_truthy
        expect(Messages::NoAttributesMessage.superclass).to be CommonDomain::Messages::Message
        expect(Messages::NoAttributesMessage.attribute_names).to be_empty
      end
      
      it 'should define simple message with provided attributes' do
        expect(Messages.const_defined?(:SimpleMessage)).to be_truthy
        expect(Messages::SimpleMessage.new(login: 'test', password: 'password')).to be_a CommonDomain::Messages::Message
        expect(Messages::SimpleMessage.attribute_names).to eql [:login, :password]
      end
      
      it 'should accept block to setup additional message stuff' do
        block_scope = nil
        ConfiguredMessages.class_eval do
          message :MessageWithBlockInitializer do
            block_scope = self
          end
        end
        expect(block_scope).to eql ConfiguredMessages::MessageWithBlockInitializer
      end
    end
    
    describe 'group' do
      it 'should define nested module' do
        expect(Messages.const_defined?(:TheGroup)).to be_truthy
        expect(Messages::TheGroup.class).to eql Module
        expect(Messages::TheGroup).to include CommonDomain::Messages::DSL
        expect(Messages::TheGroup::GroupMessage.superclass).to eql CommonDomain::Messages::Message
      end
    end
    
    describe 'setup_dsl' do
      it 'should set base class' do
        expect(ConfiguredMessages::CustomSimpleMessage.superclass).to be ConfiguredMessages::CustomMessagesClass
      end
      
      it 'should set dsl module' do
        expect(ConfiguredMessages::CustomGroup).to include ConfiguredMessages::DSL
        expect(ConfiguredMessages::CustomGroup::ConfiguredSimpleGroupMessage.superclass).to be ConfiguredMessages::CustomMessagesClass
      end
    end
  end
end