require 'spec-helper'

module EventStoreSerializationSpec
  module Messages
    include CommonDomain::Messages::Dsl
    message :EmployeeCreated, :aggregate_id, :full_name, :email
  end
  
  describe "Integration - Event Store - Serialization" do
    shared_examples_for 'serializer' do
      it 'should serialize/deserialize the message' do
        msg = Messages::EmployeeCreated.new 'emp-1', 'Employee 1', 'mail@employee-1.com'
        data = subject.serialize msg
        expect(subject.deserialize(data)).to eql msg
      end
    end
    
    describe 'yaml' do
      subject { EventStore::Persistence::Serializers::YamlSerializer.new }
      it_behaves_like 'serializer'
    end
    
    describe 'json' do
      subject { EventStore::Persistence::Serializers::JsonSerializer.new }
      it_behaves_like 'serializer'
    end
  end
end