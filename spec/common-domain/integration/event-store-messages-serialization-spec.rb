require 'spec-helper'

module EventStoreSerializationSpec
  module Messages
    include CommonDomain::Messages::Dsl
    message :EmployeeCreated, :aggregate_id, :full_name, :email
  end
  
  describe "Integration - Event Store - Serialization" do
    describe 'yaml' do
      it 'should serialize/deserialize the message' do
        subject = EventStore::Persistence::Serializers::YamlSerializer.new
        msg = Messages::EmployeeCreated.new 'emp-1', 'Employee 1', 'mail@employee-1.com'
        data = subject.serialize msg
        expect(subject.deserialize(data)).to eql msg
      end
    end
    
    describe 'json' do
      it 'should serialize/deserialize the message' do
        subject = EventStore::Persistence::Serializers::JsonSerializer.new
        msg = Messages::EmployeeCreated.new 'emp-1', 'Employee 1', 'mail@employee-1.com'
        data = subject.serialize msg
        expect(subject.deserialize(data)).to eql msg
      end
    end
  end
end