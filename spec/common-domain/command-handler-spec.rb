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
  let(:repository) { instance_double(CommonDomain::Persistence::Repository) }
  let(:persistence_factory) { instance_double(CommonDomain::PersistenceFactory, create_repository: repository )}
  subject { Class.new(CommonDomain::CommandHandler) do
    
  end.new(persistence_factory)}
  
  it "should be a kind of a MessagesHandler" do
    expect(CommonDomain::CommandHandler.new).to be_a_kind_of CommonDomain::Messages::MessagesHandler
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

  it 'should delegate begin_unit_of_work to persistence_factory' do
    headers = double(:headers)
    result = double(:result)
    b = Proc.new {}
    expect(persistence_factory).to receive(:begin_unit_of_work).with(headers, &b).and_return(result)
    expect(subject.begin_unit_of_work(headers, &b)).to be result
  end

  it 'should delegate create_repository to persistence_factory' do
    headers = double(:headers)
    repo = double(:repo)
    expect(persistence_factory).to receive(:create_repository).and_return(repo)
    expect(subject.create_repository).to be repo
  end
  
  describe 'handle DSL' do
    class TestAggregate < CommonDomain::Aggregate
      def dummy_logic 
      end
    end
    
    let(:aggregate_class) { TestAggregate }
    let(:aggregate) { aggregate_class.new }
    
    class NoAggregateIdCommand < CommonDomain::Command
    end
    
    class DummyCommand < CommonDomain::Command
      attr_reader :id
      
      class << self
        # Using dynamic attributes to simplify testing
        alias_method :command_attribute_names, :attribute_names
        def attribute_names
          @custom_attribute_names || command_attribute_names
        end
        def attribute_names=(value)
          @custom_attribute_names = value
        end
      end
    end
    
    before do
      DummyCommand.attribute_names = nil
    end
    
    class PerformDummyAction < CommonDomain::Command
      attr_reader :id
    end
    
    class PerformDummyActionCommand < CommonDomain::Command
      attr_reader :id
    end
    
    module Commands
      class PerformAnotherDummyAction < CommonDomain::Command
        attr_reader :id
      end
    end
    
    it 'should fail to handle if the command does not have an aggregate_id attribute' do
      ac = aggregate_class
      expect {
        subject.class.class_eval do
          handle(NoAggregateIdCommand).with(ac).using(:dummy_logic)
        end
      }.to raise_error ArgumentError, "Can not define handler. The command 'NoAggregateIdCommand' does not provide required 'id' attribute."
    end
    
    it 'should define a handler and route the command to the given aggregate using specified method' do
      ac = aggregate_class
      command = DummyCommand.new attributes: {id: 'aggregate-1'}, headers: {header1: 'value-1'}
      expect(persistence_factory).to receive(:create_repository) { repository }
      expect(repository).to get_by_id(aggregate_class, 'aggregate-1').and_return aggregate
      expect(repository).to receive(:save).with(aggregate, command.headers)
      subject.class.class_eval do
        handle(DummyCommand).with(ac).using(:dummy_logic)
      end
      
      expect(aggregate).to receive(:dummy_logic)
      subject.handle_message command
    end
    
    it 'should support custom id attribute' do
      ac = aggregate_class
      DummyCommand.attribute_names = [:account_id]
      command = DummyCommand.new attributes: {account_id: 'aggregate-1'}, headers: {header1: 'value-1'}
      expect(persistence_factory).to receive(:create_repository) { repository }
      expect(repository).to get_by_id(aggregate_class, 'aggregate-1').and_return aggregate
      expect(repository).to receive(:save).with(aggregate, command.headers)
      subject.class.class_eval do
        handle(DummyCommand, id: :account_id).with(ac).using(:dummy_logic)
      end
      
      expect(aggregate).to receive(:dummy_logic)
      subject.handle_message command
    end
    
    it 'should return handler value' do
      DummyCommand.attribute_names = [:id]
      ac = aggregate_class
      expect(repository).to get_by_id(aggregate_class, 'aggregate-1').and_return aggregate
      expect(repository).to receive(:save).with(aggregate, anything())
      allow(aggregate).to receive(:dummy_logic) { 'dummy-command-result' }
      subject.class.class_eval do
        handle(DummyCommand).with(ac).using(:dummy_logic)
      end
      expect(subject.handle_message DummyCommand.new id: 'aggregate-1').to eql 'dummy-command-result'
    end
    
    it 'raise error if aggregate class was not specified using with' do
      ac = aggregate_class
      subject.class.class_eval do
        handle(DummyCommand)
      end
      command = DummyCommand.new id: 'aggregate-1'
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
        cmd = DummyCommand.new id: 'aggregate-1'
        expect(aggregate).to receive(:dummy)
        subject.handle_message cmd
      end
      
      it 'should resolve two verbs ignoring command' do
        aggregate_class.class_eval { 
          def perform_dummy_action
          end
        }
        cmd = PerformDummyActionCommand.new id: 'aggregate-1'
        expect(aggregate).to receive(:perform_dummy_action)
        subject.handle_message cmd
      end
      
      it 'should resolve two verbs' do
        aggregate_class.class_eval { 
          def perform_dummy_action
          end
        }
        cmd = PerformDummyAction.new id: 'aggregate-1'
        expect(aggregate).to receive(:perform_dummy_action)
        subject.handle_message cmd
      end
      
      it 'should ignore module part' do
        aggregate_class.class_eval { 
          def perform_another_dummy_action
          end
        }
        cmd = Commands::PerformAnotherDummyAction.new id: 'aggregate-1'
        expect(aggregate).to receive(:perform_another_dummy_action)
        subject.handle_message cmd
      end
    end
    
    describe 'map arguments' do
      class TestAggregateToMapArguments < CommonDomain::Aggregate
        def test_logic(first_arg, second_arg)
        end
        
        def test_named_logic(first_arg, second_arg, named_arg1: nil, named_arg2: nil)
        end
        
        def test_optional_logic(first_arg, optional1 = nil, optional2 = nil)
        end
      end
      let(:aggregate) { TestAggregateToMapArguments.new }
      
      before(:each) do
        allow(repository).to receive(:get_by_id).with(TestAggregateToMapArguments, 'aggregate-1').and_return aggregate
        allow(repository).to receive(:save)
      end
      
      it 'should map command attributes to domain method arguments' do
        DummyCommand.attribute_names = [:id, :first_arg, :second_arg]
        subject.class.class_eval do
          handle(DummyCommand).with(TestAggregateToMapArguments).using(:test_logic)
        end
        expect(aggregate).to receive(:test_logic).with('first-arg-value', 'second-arg-value')
        cmd = DummyCommand.new id: 'aggregate-1', first_arg: 'first-arg-value', second_arg: 'second-arg-value'
        subject.handle_message(cmd)
      end
      
      it 'should map command attributes to domain method arguments with custom id' do
        DummyCommand.attribute_names = [:account_id, :first_arg, :second_arg]
        subject.class.class_eval do
          handle(DummyCommand, id: :account_id).with(TestAggregateToMapArguments).using(:test_logic)
        end
        expect(aggregate).to receive(:test_logic).with('first-arg-value', 'second-arg-value')
        cmd = DummyCommand.new account_id: 'aggregate-1', first_arg: 'first-arg-value', second_arg: 'second-arg-value'
        subject.handle_message(cmd)
      end
      
      it 'should map named command attributes' do
        DummyCommand.attribute_names = [:id, :first_arg, :second_arg, :named_arg1, :named_arg2]
        subject.class.class_eval do
          handle(DummyCommand).with(TestAggregateToMapArguments).using(:test_named_logic)
        end
        expect(aggregate).to receive(:test_named_logic).with('first-arg-value', 'second-arg-value', named_arg1: 'value-1', named_arg2: 'value-2')
        cmd = DummyCommand.new id: 'aggregate-1', first_arg: 'first-arg-value', second_arg: 'second-arg-value', named_arg1: 'value-1', named_arg2: 'value-2'
        subject.handle_message(cmd)
      end
      
      it 'should ignore missing named attributes' do
        DummyCommand.attribute_names = [:id, :first_arg, :second_arg]
        subject.class.class_eval do
          handle(DummyCommand).with(TestAggregateToMapArguments).using(:test_named_logic)
        end
        expect(aggregate).to receive(:test_named_logic).with('first-arg-value', 'second-arg-value')
        cmd = DummyCommand.new id: 'aggregate-1', first_arg: 'first-arg-value', second_arg: 'second-arg-value'
        subject.handle_message(cmd)
      end
      
      it 'should map named command attributes provided as strings' do
        DummyCommand.attribute_names = [:id, :first_arg, :second_arg, :named_arg1, :named_arg2]
        subject.class.class_eval do
          handle(DummyCommand).with(TestAggregateToMapArguments).using(:test_named_logic)
        end
        expect(aggregate).to receive(:test_named_logic).with('first-arg-value', 'second-arg-value', named_arg1: 'value-1', named_arg2: 'value-2')
        cmd = DummyCommand.new id: 'aggregate-1', "first_arg" => 'first-arg-value', "second_arg" => 'second-arg-value', "named_arg1" => 'value-1', "named_arg2" => 'value-2'
        subject.handle_message(cmd)
      end
      
      it 'should map optional arguments' do
        DummyCommand.attribute_names = [:id, :first_arg, :optional1, :optional2]
        subject.class.class_eval do
          handle(DummyCommand).with(TestAggregateToMapArguments).using(:test_optional_logic)
        end
        expect(aggregate).to receive(:test_optional_logic).with('first-arg-value', 'optional-1', 'optional-2')
        cmd = DummyCommand.new id: 'aggregate-1', first_arg: 'first-arg-value', optional1: 'optional-1', optional2: 'optional-2'
        subject.handle_message(cmd)
      end
      
      it 'should ignore missing optional arguments' do
        DummyCommand.attribute_names = [:id, :first_arg]
        subject.class.class_eval do
          handle(DummyCommand).with(TestAggregateToMapArguments).using(:test_optional_logic)
        end
        expect(aggregate).to receive(:test_optional_logic).with('first-arg-value')
        cmd = DummyCommand.new id: 'aggregate-1', first_arg: 'first-arg-value'
        subject.handle_message(cmd)
      end
      
      it 'should fail if the command does not provide some attributes' do
        DummyCommand.attribute_names = [:id, :first_arg]
        subject.class.class_eval do
          handle(DummyCommand).with(TestAggregateToMapArguments).using(:test_logic)
        end
        cmd = DummyCommand.new id: 'aggregate-1', first_arg: 'first-arg-value'
        expect { subject.handle_message(cmd) }.to raise_error ArgumentError, 'Can not map arguments. The \'test_logic\' method expects \'second_arg\' parameter but the command does not have a corresponding attribute.'
      end
      
      it 'should fail if the command has too much attributes' do
        DummyCommand.attribute_names = [:id, :first_arg, :second_arg, :new_arg]
        subject.class.class_eval do
          handle(DummyCommand).with(TestAggregateToMapArguments).using(:test_logic)
        end
        cmd = DummyCommand.new id: 'aggregate-1', first_arg: 'first-arg-value', second_arg: 'first-arg-value', new_arg: 'new-value'
        expect { subject.handle_message(cmd) }.to raise_error ArgumentError, 'Can not map arguments. The command provides \'new_arg\' attribute but the \'test_logic\' method does not have a corresponding parameter.'
      end
    end
  end
end