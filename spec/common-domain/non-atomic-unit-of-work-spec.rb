require 'spec-helper'

module NonAtomicUnitOfWorkSpec
  
  class TestAggregate1 < CommonDomain::Aggregate
  end
  
  class TestAggregate2 < CommonDomain::Aggregate
  end

  describe CommonDomain::NonAtomicUnitOfWork do
    let(:aggregate1) { TestAggregate1.new 'aggregate-1' }
    let(:aggregate2) { TestAggregate1.new 'aggregate-2' }
    let(:repository) { double(:repository) }
    
    subject { described_class::UnitOfWork.new repository }
  
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
      end
      
      it 'should save each retrieved aggregate with headers' do
        subject.get_by_id TestAggregate1, 'aggregate-1'
        subject.get_by_id TestAggregate2, 'aggregate-2'
        expect(repository).to receive(:save).with(aggregate1, with_dummy_headers)
        expect(repository).to receive(:save).with(aggregate2, with_dummy_headers)
        subject.commit dummy_headers
      end
      
      it 'should save newly created aggregate' do
        subject.add_new aggregate1
        subject.add_new aggregate2
        expect(repository).to receive(:save).with(aggregate1, with_dummy_headers)
        expect(repository).to receive(:save).with(aggregate2, with_dummy_headers)
        subject.commit dummy_headers
      end
    end
    
    describe 'begin_unit_of_work' do
      let(:repository_factory) { double(:repository_factory, create_repository: repository) }
      let(:uow) { double(:uow) }
      include CommonDomain::NonAtomicUnitOfWork
      
      it 'should create the unit of work, yield it and commit with headers' do
        expect(repository_factory).to receive(:create_repository) { repository }
        expect(described_class::UnitOfWork).to receive(:new) { uow }
        expect(uow).to receive(:commit).with(with_dummy_headers)
        expect { |b| begin_unit_of_work(dummy_headers, &b) }.to yield_with_args(uow)
      end
      
      it 'should return block return value' do
        expect(begin_unit_of_work(dummy_headers) {|uow| 100 }).to eql(100)
      end
    end
  end
end