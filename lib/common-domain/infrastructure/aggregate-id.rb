module CommonDomain::Infrastructure
  class AggregateId
    require 'securerandom'
    def self.new_id
      SecureRandom.uuid
    end
  end
end