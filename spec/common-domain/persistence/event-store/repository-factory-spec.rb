require 'spec-helper'

describe CommonDomain::Persistence::EventStore::RepositoryFactory do
  let(:builder) { double(:aggregate_builder) }
  let(:event_store) { double(:event_store) }
  let(:snapshots_repo) { double(:event_store) }

  subject { described_class.new event_store, builder, snapshots_repo }
  
  describe 'create_repository' do
    it 'should create a new instance of the repository' do
      expect(subject.create_repository).to be_an_instance_of(CommonDomain::Persistence::EventStore::Repository)
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