require 'spec-helper'

describe "sql-projections-matcher" do
  include SqlConnectionHelper
  let(:connection) { sqlite_memory_connection }
  
  before(:each) do
    connection.create_table :departments do
      Int :id, :primary_key=>true, :size => 50, :null=>false
      String :name, :size => 50, :null=>false
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
end