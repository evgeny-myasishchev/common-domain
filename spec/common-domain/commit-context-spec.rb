require 'spec-helper'

describe CommonDomain::CommitContext do
  it 'should initialize attributes from commit' do
    commit = EventStore::Commit.new(stream_id: 'stream-100',
      commit_id: 'commit-110',
      commit_timestamp: DateTime.new,
      headers: {header1: 'value-1', header2: 'value-2'})
    subject = described_class.new commit
    expect(subject.commit_id).to eql 'commit-110'
    expect(subject.commit_timestamp).to eql commit.commit_timestamp
    expect(subject.headers).to eql commit.headers
  end
end