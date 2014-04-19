require 'spec-helper'

describe "sql-projections-matcher" do
  include SqlConnectionHelper
  let(:connection) { sqlite_memory_connection }
  
  before(:each) do
    connection.create_table :departments do
      String :id, primary_key: true, allow_null: false
      String :name, size: 50, allow_null: true
    end
  end
  
  describe "have_table" do
    it "should pass if table exists" do
      connection.should have_table :departments
    end
    
    it "should yield the block with the corresponding table" do
      expect { |block| connection.should have_table(:departments, &block) }.to yield_with_args(connection[:departments])
    end
    
    it "should fail if table does not exists" do
      lambda { connection.should have_table(:unknown_table) }.should raise_error(RSpec::Expectations::ExpectationNotMetError)
    end
    
    describe "failure_messages" do
      subject {
        m = have_table :departments
        m.matches?(connection)
        m
      }
      
      it "should tell that table does not exist for should" do
        subject.failure_message_for_should.should eql "expected #{connection} to have table departments"
      end
      
      it "should tell that table does not exist for should_not" do
        subject.failure_message_for_should_not.should eql "expected #{connection} not to have table departments"
      end
    end
  end
  
  describe "have_column" do
    let(:actual) { connection[:departments] }
    
    it "should pass if given column exists" do
      have_column(:id, type: :string, primary_key: true, allow_null: false).matches?(actual).should be_true
    end
    
    it "should fail if given column does not exists" do
      have_column(:unknown, type: :string, primary_key: true, allow_null: false).matches?(actual).should be_false
    end
    
    it "should fail if some attributes doesn't match" do
      have_column(:id, type: :int, primary_key: true, allow_null: false).matches?(actual).should be_false
    end
    
    it "should handle null" do
      have_column(:name, allow_null: true).matches?(actual).should be_true
      have_column(:name, allow_null: false).matches?(actual).should be_false
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
        not_existing.failure_message_for_should.should eql "table departments expected to have column [unknown, {:type=>:string, :primary_key=>true, :allow_null=>false}] but no column found"
      end
      
      it "should tell there expected column is different from actual" do
        existing.failure_message_for_should.should eql "table departments expected to have column [id, {:type=>:string, :primary_key=>true, :allow_null=>false}] but was [:id, {:allow_null=>false, :default=>nil, :primary_key=>true, :db_type=>\"varchar(255)\", :type=>:string, :ruby_default=>nil}] (specified only attribs are matched)"
      end
      
      it "should tell that the column was not expected" do
        existing.failure_message_for_should_not.should eql "table departments expected not to have column [id, {:type=>:string, :primary_key=>true, :allow_null=>false}]"
        not_existing.failure_message_for_should_not.should eql "table departments expected not to have column [unknown, {:type=>:string, :primary_key=>true, :allow_null=>false}]"
      end
    end
  end
end