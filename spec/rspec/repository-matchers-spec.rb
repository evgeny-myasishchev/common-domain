require 'spec-helper'

describe "work-matchers" do
  let(:repository) { double(:repository) }
  
  describe "get_by_id" do
    let(:aggregate_class) { double(:aggregate_class) }
    let(:aggregate_instance) { double(:aggregate_instance) }
    
    it "should fail if no aggregate_class or aggregate_id supplied" do
      expect(lambda { repository.to get_by_id }).to raise_error("aggregate_class should be supplied")
      expect(lambda { repository.to get_by_id(aggregate_class) }).to raise_error("aggregate_id should be supplied")
    end
    
    it "should setup get_by_id with aggregate_class and aggregate_id and return aggregate_instance" do
      expect(repository).to get_by_id(aggregate_class, 'aggregate-100').and_return aggregate_instance
      expect(repository.get_by_id(aggregate_class, 'aggregate-100')).to be aggregate_instance
    end
    
    it 'should fail if return chain not performed' do
      expect {
        expect(repository).to get_by_id(aggregate_class, 'aggregate-100')
      }.to raise_error 'please provide aggregate instance with and_return chain'
    end
    
    describe 'save chain' do
      it 'should setup save with headers' do
        headers = {header1: 'value1', header2: 'value2'}
        expect(repository).to get_by_id(aggregate_class, 'aggregate-100').and_return(aggregate_instance).and_save(headers)
        expect(repository.get_by_id(aggregate_class, 'aggregate-100')).to be aggregate_instance
        repository.save(aggregate_instance, headers)
      end
      
      it 'should setup save with headers and transaction context' do
        headers = {header1: 'value1', header2: 'value2'}
        transaction_context = EventStore::Persistence::PersistenceEngine::TransactionContext
        expect(repository).to get_by_id(aggregate_class, 'aggregate-100').and_return(aggregate_instance).and_save(headers, transaction_context)
        expect(repository.get_by_id(aggregate_class, 'aggregate-100')).to be aggregate_instance
        repository.save(aggregate_instance, headers, transaction_context)
      end
      
      it 'should fail if headers are nil' do
        expect {
          expect(repository).to get_by_id(aggregate_class, 'aggregate-100').and_return(aggregate_instance).and_save(nil)
        }.to raise_error 'please provide expected headers to save with the aggregate'
      end
      
      it 'should provide dummy_headers helpers' do
        expect(repository).to get_by_id(aggregate_class, 'aggregate-100').and_return(aggregate_instance).and_save(with_dummy_headers)
        repository.get_by_id(aggregate_class, 'aggregate-100')
        repository.save(aggregate_instance, dummy_headers)
      end
    end
  end
end