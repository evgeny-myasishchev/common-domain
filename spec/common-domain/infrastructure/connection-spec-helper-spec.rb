require 'spec-helper'

describe CommonDomain::Infrastructure::ConnectionSpecHelper do
  include described_class
  describe 'make_sequel_friendly' do
    let(:original_spec) { Hash.new }
    
    it 'should make a copy of original spec' do
      expect(make_sequel_friendly(original_spec)).not_to be original_spec
    end
    
    it 'should replace sqlite3 adapter with sqlite' do
      original_spec['adapter'] = 'sqlite3'
      expect(make_sequel_friendly(original_spec)['adapter']).to eql 'sqlite'
    end
    
    it 'should replace postgresql adapter with postgres' do
      original_spec['adapter'] = 'postgresql'
      expect(make_sequel_friendly(original_spec)['adapter']).to eql 'postgres'
    end
  end
end