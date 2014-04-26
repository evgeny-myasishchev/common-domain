module CommonDomain::Projections
  module ActiveRecord
    def self.included(receiver)
      receiver.extend CommonDomain::Projections::Base
    end
  end
end