module CommonDomain::Infrastructure
  module ConnectionSpecHelper
    
    # Active record adapters and potentially some other attributes may be slightly different
    # This method adjusts those inconsistencies
    def make_sequel_friendly spec
      normalized_spec = spec.dup
      normalized_spec['adapter'] = 'sqlite' if(normalized_spec['adapter'] == 'sqlite3')
      normalized_spec
    end
  end
end