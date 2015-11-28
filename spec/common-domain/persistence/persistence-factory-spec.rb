require 'spec-helper'

describe CommonDomain::PersistenceFactory do
  let(:builder) { instance_double(CommonDomain::Persistence::AggregatesBuilder) }
  let(:event_store) { instance_double(EventStore::Base) }
  let(:snapshots_repo) { instance_double(CommonDomain::Persistence::Snapshots) }

  subject { described_class.new event_store, builder, snapshots_repo }
  
  describe 'create_repository' do
    it 'should create a new instance of the repository' do
      expect(subject.create_repository).to be_an_instance_of(CommonDomain::Persistence::Repository)
    end
    
    it 'should add all registered hooks to a newly created repository' do
      hook1 = {after_commit: -> {}}
      hook2 = {after_commit: -> {}}
      subject.hook hook1
      subject.hook hook2
      
      repo = instance_double(CommonDomain::Persistence::Repository)
      expect(CommonDomain::Persistence::Repository).to receive(:new) { repo }
      expect(repo).to receive(:hook).with hook1
      expect(repo).to receive(:hook).with hook2
      subject.create_repository
    end
  end

  describe 'begin_unit_of_work' do
    let(:repository) { instance_double(CommonDomain::Persistence::Repository) }
    let(:uow) { instance_double(CommonDomain::UnitOfWork, commit: nil) }
    
    before do
      allow(subject).to receive(:create_repository) { repository }
      allow(CommonDomain::UnitOfWork).to receive(:new) { uow }
    end
    
    it 'should create the unit of work, yield it and commit with headers' do
      expect(subject).to receive(:create_repository) { repository }
      expect(CommonDomain::UnitOfWork).to receive(:new) { uow }
      expect(uow).to receive(:commit).with(with_dummy_headers)
      expect { |b| subject.begin_unit_of_work(dummy_headers, &b) }.to yield_with_args(uow)
    end
    
    it 'should return block return value' do
      expect(subject.begin_unit_of_work(dummy_headers) {|uow| 100 }).to eql(100)
    end
    
    it 'should add all registered hooks to a newly created unit of work' do
      hook1 = {after_commit: -> {}}
      hook2 = {after_commit: -> {}}
      subject.hook hook1
      subject.hook hook2
      
      uow = instance_double(CommonDomain::UnitOfWork, commit: nil)
      expect(CommonDomain::UnitOfWork).to receive(:new) { uow }
      expect(uow).to receive(:hook).with hook1
      expect(uow).to receive(:hook).with hook2
      subject.begin_unit_of_work({}) {}
    end
  end
end