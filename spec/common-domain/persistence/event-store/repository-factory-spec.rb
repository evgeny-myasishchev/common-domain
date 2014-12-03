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
end