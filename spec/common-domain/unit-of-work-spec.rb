require 'spec-helper'

module UnitOfWorkSpec
  
  class TestAggregate1 < CommonDomain::Aggregate
  end
  
  class TestAggregate2 < CommonDomain::Aggregate
  end
  
  describe CommonDomain::UnitOfWork do
    let(:aggregate1) { TestAggregate1.new 'aggregate-1' }
    let(:aggregate2) { TestAggregate1.new 'aggregate-2' }
    let(:persistence_engine) { instance_double(EventStore::Persistence::PersistenceEngine, :'supports_transactions?' => true)}
    let(:repository) { subject.repository }
    let(:event_store) { instance_double(EventStore::Base, persistence_engine: persistence_engine) }
    
    subject { described_class.new instance_double(CommonDomain::Persistence::Repository, event_store: event_store) }

    it 'should fail to initialize if persistence engine does not support transactions' do
      expect(persistence_engine).to receive(:'supports_transactions?') { false }
      expect { described_class.new subject.repository }.to raise_error 'Can not use UnitOfWork. Underlying persistence engine does not support transactions.'
    end
    
    describe 'get_by_id' do
      it 'should use the repository to get the aggregate by id' do
        expect(repository).to receive(:get_by_id).with(TestAggregate1, 'aggregate-1').and_return(aggregate1)
        expect(repository).to receive(:get_by_id).with(TestAggregate2, 'aggregate-2').and_return(aggregate2)
        
        expect(subject.get_by_id(TestAggregate1, 'aggregate-1')).to eql aggregate1
        expect(subject.get_by_id(TestAggregate2, 'aggregate-2')).to eql aggregate2
      end
      
      it 'should maintain identity map and return same aggregate on subsequent requests to the same aggregate' do
        expect(repository).to receive(:get_by_id).with(TestAggregate1, 'aggregate-1').once.and_return(aggregate1)
        expect(subject.get_by_id(TestAggregate1, 'aggregate-1')).to be subject.get_by_id(TestAggregate1, 'aggregate-1')
      end
    end
    
    describe 'commit' do
      before(:each) do
        allow(repository).to receive(:get_by_id).with(TestAggregate1, 'aggregate-1').and_return(aggregate1)
        allow(repository).to receive(:get_by_id).with(TestAggregate2, 'aggregate-2').and_return(aggregate2)
        allow(repository).to receive(:event_store) { event_store }
        allow(event_store).to receive(:transaction) do |&block|
          block.call
        end
      end
      
      it 'should save each aggregate with headers within the transaction' do
        expect(event_store).to receive(:transaction) do |&block|
          block.call
        end
        subject.get_by_id TestAggregate1, 'aggregate-1'
        subject.get_by_id TestAggregate2, 'aggregate-2'
        expect(repository).to receive(:save).with(aggregate1, with_dummy_headers)
        expect(repository).to receive(:save).with(aggregate2, with_dummy_headers)
        subject.commit dummy_headers
      end
      
      it 'should save newly created aggregates' do
        subject.add_new aggregate1
        subject.add_new aggregate2
        expect(repository).to receive(:save).with(aggregate1, with_dummy_headers)
        expect(repository).to receive(:save).with(aggregate2, with_dummy_headers)
        subject.commit dummy_headers
      end
    end
  end
end