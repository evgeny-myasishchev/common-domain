class CommonDomain::CommitContext
  attr_reader :commit_id, :commit_timestamp, :headers
  def initialize(commit)
    @commit_id = commit.commit_id
    @commit_timestamp = commit.commit_timestamp
    @headers = commit.headers
  end
end