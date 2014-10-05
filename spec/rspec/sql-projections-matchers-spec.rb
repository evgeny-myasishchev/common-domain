require 'spec-helper'

describe "sql-projections-matcher" do
  include SqlConnectionHelper
  let(:connection) { open_sequel_connection }
  
  before(:each) do
    connection.drop_table? :departments
    connection.create_table :departments do
      String :id, primary_key: true, allow_null: false
      String :name, size: 50, allow_null: true
    end
  end
  
  describe "have_table" do
    it "should pass if table exists" do
      expect(connection).to have_table :departments
    end
      
    it "should work if table name is string" do
      expect(connection).to have_table 'departments' do |table|
        expect(table.opts[:from]).to eql [:departments]
      end
    end
    
    it "should yield the block with the corresponding table" do
      expect { |block| 
        expect(connection).to have_table(:departments) {|table| block.to_proc.call(table)}
      }.to yield_with_args(connection[:departments])
      
      expect { |block| 
        expect(connection).to have_table(:departments) do |table|
          block.to_proc.call(table)
        end
      }.to yield_with_args(connection[:departments])
    end
    
    it "should fail if table does not exists" do
      expect{ expect(connection).to have_table(:unknown_table) }.to raise_error(RSpec::Expectations::ExpectationNotMetError)
    end
    
    describe "failure_messages" do
      subject {
        m = have_table :departments
        m.matches?(connection)
        m
      }
      
      it "should tell that table does not exist for should" do
        expect(subject.failure_message).to eql "expected #{connection} to have table departments"
      end
      
      it "should tell that table does not exist for should_not" do
        expect(subject.failure_message_when_negated).to eql "expected #{connection} not to have table departments"
      end
    end
  end
  
  describe "have_column" do
    let(:actual) { connection[:departments] }
    
    it "should pass if given column exists" do
      expect(have_column(:id, type: :string, primary_key: true, allow_null: false).matches?(actual)).to be_truthy
    end
    
    it "should fail if given column does not exists" do
      expect(have_column(:unknown, type: :string, primary_key: true, allow_null: false).matches?(actual)).to be_falsey
    end
    
    it "should fail if some attributes doesn't match" do
      expect(have_column(:id, type: :int, primary_key: true, allow_null: false).matches?(actual)).to be_falsey
    end
    
    it "should handle null" do
      expect(have_column(:name, allow_null: true).matches?(actual)).to be_truthy
      expect(have_column(:name, allow_null: false).matches?(actual)).to be_falsey
    end
    
    describe "failure_messages" do
      let(:existing) { 
        m = have_column(:id, type: :string, primary_key: true, allow_null: false)
        m.matches?(actual)
        m
      }
      
      let(:not_existing) { 
        m = have_column(:unknown, type: :string, primary_key: true, allow_null: false)
        m.matches?(actual)
        m
      }
      
      it "should tell there is no such column" do
        expect(not_existing.failure_message).to eql "table departments expected to have column [unknown, {:type=>:string, :primary_key=>true, :allow_null=>false}] but no column found"
      end
      
      it "should tell there expected column is different from actual" do
        expect(existing.failure_message).to match /table departments expected to have column \[id, .*\] but was \[:id, .*\] \(specified only attribs are matched\)/
      end
      
      it "should tell that the column was not expected" do
        expect(existing.failure_message_when_negated).to eql "table departments expected not to have column [id, {:type=>:string, :primary_key=>true, :allow_null=>false}]"
        expect(not_existing.failure_message_when_negated).to eql "table departments expected not to have column [unknown, {:type=>:string, :primary_key=>true, :allow_null=>false}]"
      end
    end
  end
end