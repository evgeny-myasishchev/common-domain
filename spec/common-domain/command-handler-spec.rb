require 'spec-helper'

describe CommonDomain::CommandHandler do
  module Messages
    class Dummy
      attr_accessor :headers
    end
    class Dummy1
      attr_accessor :headers
    end
  end
  let(:repository) { double(:repository) }
  subject { Class.new(CommonDomain::CommandHandler) do
    
  end.new(repository)}
  
  it "should be a kind of a MessagesHandler" do
    expect(CommonDomain::CommandHandler.new).to be_a_kind_of CommonDomain::Infrastructure::MessagesHandler
  end
  
  it "should handle messages" do
    expected = Messages::Dummy.new
    actual = nil
    subject.class.class_eval do
      on(Messages::Dummy) { |message| actual = message }
    end
    subject.handle_message expected
    expect(actual).to be expected
  end
  
  it "should fail to define handler with headers" do
    expect {
      subject.class.class_eval do
        on(Messages::Dummy) { |message, headers|  }
      end
    }.to raise_error ArgumentError, 'Messages::Dummy handler block is expected to receive single arguemnt that would be the command itself.'
  end
  
  describe 'handle DSL' do
    class TestAggregate < CommonDomain::Aggregate
      def dummy_logic 
      end
    end
    
    let(:aggregate_class) { TestAggregate }
    let(:aggregate) { aggregate_class.new }
    
    class DummyCommand < CommonDomain::Command
    end
    
    class PerformDummyAction < CommonDomain::Command
    end
    
    class PerformDummyActionCommand < CommonDomain::Command
    end
    
    module Commands
      class PerformAnotherDummyAction < CommonDomain::Command
      end
    end
    
    it 'should define a handler and route the command to the given aggregate using specified method' do
      ac = aggregate_class
      command = DummyCommand.new 'aggregate-1', headers: {header1: 'value-1'}
      expect(repository).to get_by_id(aggregate_class, 'aggregate-1').and_return aggregate
      expect(repository).to receive(:save).with(aggregate, command.headers)
      subject.class.class_eval do
        handle(DummyCommand).with(ac).using(:dummy_logic)
      end
      
      expect(aggregate).to receive(:dummy_logic)
      subject.handle_message command
    end
    
    it 'raise error if aggregate class was not specified using with' do
      ac = aggregate_class
      subject.class.class_eval do
        handle(DummyCommand)
      end
      command = DummyCommand.new 'aggregate-1'
      expect { subject.handle_message(command) }.to raise_error 'aggregate_class is not defined for command \'DummyCommand\' handler definition'
    end
    
    describe 'resolve method name' do
      before(:each) do
        ac = aggregate_class
        expect(repository).to get_by_id(aggregate_class, 'aggregate-1').and_return aggregate
        expect(repository).to receive(:save).with(aggregate, anything())
        subject.class.class_eval do
          handle(DummyCommand).with(ac)
          handle(PerformDummyAction).with(ac)
          handle(PerformDummyActionCommand).with(ac)
          handle(Commands::PerformAnotherDummyAction).with(ac)
        end
      end
      
      it 'should resolve one verb ignoring command' do
        aggregate_class.class_eval { 
          def dummy
          end
        }
        cmd = DummyCommand.new 'aggregate-1'
        expect(aggregate).to receive(:dummy)
        subject.handle_message cmd
      end
      
      it 'should resolve two verbs ignoring command' do
        aggregate_class.class_eval { 
          def perform_dummy_action
          end
        }
        cmd = PerformDummyActionCommand.new 'aggregate-1'
        expect(aggregate).to receive(:perform_dummy_action)
        subject.handle_message cmd
      end
      
      it 'should resolve two verbs' do
        aggregate_class.class_eval { 
          def perform_dummy_action
          end
        }
        cmd = PerformDummyAction.new 'aggregate-1'
        expect(aggregate).to receive(:perform_dummy_action)
        subject.handle_message cmd
      end
      
      it 'should ignore module part' do
        aggregate_class.class_eval { 
          def perform_another_dummy_action
          end
        }
        cmd = Commands::PerformAnotherDummyAction.new 'aggregate-1'
        expect(aggregate).to receive(:perform_another_dummy_action)
        subject.handle_message cmd
      end
    end
    
    describe 'map arguments' do
      class TestAggregateToMapArguments < CommonDomain::Aggregate
        def test_logic(first_arg, second_arg)
        end
      end
      let(:aggregate) { TestAggregateToMapArguments.new }
      
      before(:each) do
        allow(repository).to receive(:get_by_id).with(TestAggregateToMapArguments, 'aggregate-1').and_return aggregate
        allow(repository).to receive(:save)
      end
      
      it 'should map command attributes to domain method arguments' do
        subject.class.class_eval do
          handle(DummyCommand).with(TestAggregateToMapArguments).using(:test_logic)
        end
        expect(aggregate).to receive(:test_logic).with('first-arg-value', 'second-arg-value')
        cmd = DummyCommand.new 'aggregate-1', first_arg: 'first-arg-value', second_arg: 'second-arg-value'
        subject.handle_message(cmd)
      end
      
      it 'should fail if the command does not provide some attributes' do
        subject.class.class_eval do
          handle(DummyCommand).with(TestAggregateToMapArguments).using(:test_logic)
        end
        cmd = DummyCommand.new 'aggregate-1', first_arg: 'first-arg-value'
        expect { subject.handle_message(cmd) }.to raise_error ArgumentError, 'Can not map arguments. The \'test_logic\' method expects \'second_arg\' parameter but the command does not have a corresponding attribute.'
      end
      
      it 'should fail if the command has too much attributes' do
        subject.class.class_eval do
          handle(DummyCommand).with(TestAggregateToMapArguments).using(:test_logic)
        end
        cmd = DummyCommand.new 'aggregate-1', first_arg: 'first-arg-value', second_arg: 'first-arg-value', new_arg: 'new-value'
        expect { subject.handle_message(cmd) }.to raise_error ArgumentError, 'Can not map arguments. The command provides \'new_arg\' attribute but the \'test_logic\' method does not have a corresponding parameter.'
      end
    end
  end
end