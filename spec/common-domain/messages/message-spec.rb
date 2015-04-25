require 'spec-helper'

module CommonDomainMessagesMessageSpec
  class NoAttribsMessage < CommonDomain::Messages::Message
  end
  
  class SimpleMessage < CommonDomain::Messages::Message
    attr_reader :name, :email
  end
  
  class AnotherSimpleMessage < CommonDomain::Messages::Message
    attr_reader :cell_phone, :email_address
  end
  
  describe CommonDomain::Messages::Message do
    describe 'initializer' do
      it 'should initialize the message with no attributes' do
        expect { NoAttribsMessage.new }.not_to raise_error
      end
      
      it 'should initialize the message with attribute provided as hash' do
        msg = SimpleMessage.new name: 'name-232', email: 'email-100'
        expect(msg.name).to eql 'name-232'
        expect(msg.email).to eql 'email-100'
        
        msg = AnotherSimpleMessage.new cell_phone: 'phone-33223', email_address: 'email-address-100'
        expect(msg.cell_phone).to eql 'phone-33223'
        expect(msg.email_address).to eql 'email-address-100'
      end
      
      it 'should ignore extra hash values' do
        msg = SimpleMessage.new name: 'name-232', email: 'email-100', extra1: 'false', extra2: 'true'
        expect(msg.instance_variable_names).not_to include("@extra1")
        expect(msg.instance_variable_names).not_to include("@extra2")
      end
      
      it 'should initialize the message with attributes provided as normal arguments' do
        msg = SimpleMessage.new 'name-232', 'email-100'
        expect(msg.name).to eql 'name-232'
        expect(msg.email).to eql 'email-100'
        
        msg = AnotherSimpleMessage.new 'phone-33223', 'email-address-100'
        expect(msg.cell_phone).to eql 'phone-33223'
        expect(msg.email_address).to eql 'email-address-100'
      end
      
      it 'should raise ArgumentError if number of normal arguments is wrong' do
        expect { SimpleMessage.new 'name-232' }.to raise_error ArgumentError, "Expected 2 arguments: name, email, got 1."
      end
    end
    
    describe 'attribute_names' do
      it 'should provide attribute_names on class level' do
        expect(NoAttribsMessage.attribute_names).to be_empty
        expect(SimpleMessage.attribute_names).to eql [:name, :email]
        expect(AnotherSimpleMessage.attribute_names).to eql [:cell_phone, :email_address]
      end
      
      it 'should provide attribute_names on instance level' do
        expect(NoAttribsMessage.new({}).attribute_names).to be_empty
        expect(SimpleMessage.new({}).attribute_names).to eql [:name, :email]
        expect(AnotherSimpleMessage.new({}).attribute_names).to eql [:cell_phone, :email_address]
      end
    end
    
    describe 'from_hash' do
      it 'should instantiate the message with provided hash' do
        msg = SimpleMessage.from_hash name: 'name-232', email: 'email-100'
        expect(msg.name).to eql 'name-232'
        expect(msg.email).to eql 'email-100'
      end
        
      it 'should fail if the arg is not hash' do
        expect { SimpleMessage.from_hash 'fake' }.to raise_error ArgumentError, 'Expected argument to be Hash, got: fake'
      end
    end
  end

end