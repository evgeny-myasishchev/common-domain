require 'spec-helper'

module UnitOfWorkSpec
  
  class TestAggregate1 < CommonDomain::Aggregate
  end
  
  class TestAggregate2 < CommonDomain::Aggregate
  end
  
  shared_examples_for 'unit of work' do
    let(:aggregate1) { TestAggregate1.new 'aggregate-1' }
    let(:aggregate2) { TestAggregate1.new 'aggregate-2' }
    let(:repository) { subject.repository }
    
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
    
    describe 'begin_unit_of_work' do
      let(:repository_factory) { double(:repository_factory, create_repository: repository) }
      let(:uow) { double(:uow, commit: nil) }
      include described_class.parent
      
      before do
        allow(repository_factory).to receive(:create_repository) { repository }
        allow(described_class).to receive(:new) { uow }
      end
      
      it 'should create the unit of work, yield it and commit with headers' do
        expect(repository_factory).to receive(:create_repository) { repository }
        expect(described_class).to receive(:new) { uow }
        expect(uow).to receive(:commit).with(with_dummy_headers)
        expect { |b| begin_unit_of_work(dummy_headers, &b) }.to yield_with_args(uow)
      end
      
      it 'should return block return value' do
        expect(begin_unit_of_work(dummy_headers) {|uow| 100 }).to eql(100)
      end
    end
  end

  describe CommonDomain::UnitOfWork::NonAtomic::NonAtomicUnitOfWork do
    let(:aggregate1) { TestAggregate1.new 'aggregate-1' }
    let(:aggregate2) { TestAggregate1.new 'aggregate-2' }
    let(:repository) { subject.repository }
    
    subject { described_class.new double(:repository) }
    
    it_behaves_like 'unit of work'
    
    describe 'commit' do
      before(:each) do
        allow(repository).to receive(:get_by_id).with(TestAggregate1, 'aggregate-1').and_return(aggregate1)
        allow(repository).to receive(:get_by_id).with(TestAggregate2, 'aggregate-2').and_return(aggregate2)
      end
      
      it 'should save each retrieved aggregates with headers' do
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
  
  describe CommonDomain::UnitOfWork::Atomic::AtomicUnitOfWork do
    let(:aggregate1) { TestAggregate1.new 'aggregate-1' }
    let(:aggregate2) { TestAggregate1.new 'aggregate-2' }
    let(:persistence_engine) { double(:persistence_engine, :'supports_transactions?' => true)}
    let(:repository) { subject.repository }
    let(:event_store) { double(:event_store, persistence_engine: persistence_engine) }
    
    subject { described_class.new double(:repository, event_store: event_store) }
    
    it_behaves_like 'unit of work'
    
    describe 'commit' do
      let(:transaction_context) { double(:transaction_context) }
      
      before(:each) do
        allow(repository).to receive(:get_by_id).with(TestAggregate1, 'aggregate-1').and_return(aggregate1)
        allow(repository).to receive(:get_by_id).with(TestAggregate2, 'aggregate-2').and_return(aggregate2)
        allow(repository).to receive(:event_store) { event_store }
        allow(event_store).to receive(:transaction) do |&block|
          block.call(transaction_context)
        end
      end
      
      it 'should save each retrieved aggregates with headers within the transaction' do
        expect(event_store).to receive(:transaction) do |&block|
          block.call(transaction_context)
        end
        subject.get_by_id TestAggregate1, 'aggregate-1'
        subject.get_by_id TestAggregate2, 'aggregate-2'
        expect(repository).to receive(:save).with(aggregate1, with_dummy_headers, transaction_context)
        expect(repository).to receive(:save).with(aggregate2, with_dummy_headers, transaction_context)
        subject.commit dummy_headers
      end
      
      it 'should save newly created aggregates' do
        subject.add_new aggregate1
        subject.add_new aggregate2
        expect(repository).to receive(:save).with(aggregate1, with_dummy_headers, transaction_context)
        expect(repository).to receive(:save).with(aggregate2, with_dummy_headers, transaction_context)
        subject.commit dummy_headers
      end
      
      it 'should fail to initialize if persistence engine does not support transactions' do
        expect(persistence_engine).to receive(:'supports_transactions?') { false }
        expect { described_class.new subject.repository }.to raise_error 'Can not use AtomicUnitOfWork. Underlying persistence engine does not support transactions.'
      end
    end
  end
end