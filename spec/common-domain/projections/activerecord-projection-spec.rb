require 'spec-helper'

describe CommonDomain::Projections::ActiveRecord do
  include ActiveRecordHelpers
  establish_activerecord_connection
  
  class ProjectionModel < ActiveRecord::Base
    include CommonDomain::Projections::ActiveRecord
  end
  
  subject { ProjectionModel.create_projection }
  
  before(:each) do
    c = ActiveRecord::Base.connection
  end
  
  describe 'projection instance' do
    it 'should create instance of the projection class' do
      expect(subject).to be_a ProjectionModel::Projection
    end
    
    it 'should invoke the projection block in context of projection class' do
      ProjectionModel.projection do
        def self.get_the_self
          self
        end
        
        def get_the_self
          self
        end
      end
      expect(subject.class.get_the_self).to eql subject.class
      expect(subject.get_the_self).to eql subject
    end
    
    it 'should supply create_projection args to the projection configuration block' do
      ProjectionModel.projection do |*args|
        @method_args = args
        def self.the_args
          @method_args
        end
      end
      projection = ProjectionModel.create_projection 100, "arg-2", "arg-3"
      expect(projection.class.the_args).to eql [100, 'arg-2', 'arg-3']
    end
    
    it 'should use model class name as an identifier' do
      expect(subject.identifier).to eql ProjectionModel.name
    end
  end
  
  it 'should create class once' do
    expect(subject.class).to eql ProjectionModel.create_projection.class
  end
  
  it 'should assign const for the class' do
    expect(subject.class.name).to eql 'ProjectionModel::Projection'
  end
  
  describe 'purge!' do
    it 'it should delete all' do
      expect(ProjectionModel).to receive(:delete_all)
      ProjectionModel.create_projection.purge!
    end
  end
  
  describe 'events_handling' do
    module ArProjectionSpecEvents
      include CommonDomain::DomainEvent::DSL
      event :EmployeeCreated, :aggregate_id
      event :EmployeeChanged, :aggregate_id
      event :EmployeeRemoved, :aggregate_id
    end
    
    it 'should handle events' do
      ProjectionModel.class_eval do
        projection do
          def handled_events
            @handled_events ||= []
          end
          on(ArProjectionSpecEvents::EmployeeCreated) { |event| handled_events << event }
          on(ArProjectionSpecEvents::EmployeeRemoved) { |event| handled_events << event }
        end
      end
      
      e1 = ArProjectionSpecEvents::EmployeeCreated.new('e-1')
      e2 = ArProjectionSpecEvents::EmployeeChanged.new('e-2')
      e3 = ArProjectionSpecEvents::EmployeeRemoved.new('e-3')
      expect(subject.can_handle_message?(e1)).to be_truthy
      expect(subject.can_handle_message?(e2)).to be_falsey
      expect(subject.can_handle_message?(e3)).to be_truthy
      subject.handle_message(e1)
      subject.handle_message(e3)
      expect(subject.handled_events.length).to eql(2)
      expect(subject.handled_events).to include(e1)
      expect(subject.handled_events).to include(e3)
    end
  end
end