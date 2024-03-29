# frozen_string_literal: true

require 'spec_helper'
require 'active_model'
require 'rails_use_case'

# A example model
class Order
  include ActiveModel::Model

  attr_accessor :payment_type

  validates_presence_of :payment_type

  def save
    @new_record = false
    true
  end

  def new_record?
    return true if @new_record.nil?

    @new_record
  end

  def bar
    true
  end

  def foo
    true
  end
end

# Test behavior
module ExampleBehavior
  def method_from_behavior
    true
  end
end

# Test implementation of the UseCase
class UseCaseTestImpl < Rails::UseCase
  with ExampleBehavior

  attr_accessor :order

  validates :order, presence: true

  record :order

  step :do_things
  step :something, do: -> { record.foo }
  step { record.bar }

  def do_things
    true
  end
end

# Test implementation of the UseCase which fails via falsy steps
class UseCaseTestImplFail < Rails::UseCase
  attr_accessor :order

  validates :order, presence: true

  step :do_things

  def do_things
    @record = order
    false
  end
end


# Test implementation of the UseCase which fails via fail!
class UseCaseTestImplFail2 < Rails::UseCase
  attr_accessor :order

  validates :order, presence: true

  step :do_things

  def do_things
    @record = order
    fail! code: :foobar, message: 'Something went wrong'
  end
end

# Test implementation of the UseCase which uses if to skip a step
class UseCaseTestImplSkipIf < Rails::UseCase
  attr_accessor :order

  validates :order, presence: true

  step :do_things
  step :dont_do_this, if: -> { false }

  def do_things
    @record = order
  end

  def dont_do_this
    raise "You shouldn't have did that!"
  end
end

# Test implementation of the UseCase which uses unless to skip a step
class UseCaseTestImplSkipUnless < Rails::UseCase
  attr_accessor :order

  validates :order, presence: true

  step :do_things
  step :dont_do_this, unless: -> { true }

  def do_things
    @record = order

    record.bar
  end

  def dont_do_this
    raise "You shouldn't have did that!"
  end
end

# Test implementation of the UseCase which uses succeed
class UseCaseTestImplSuccess < Rails::UseCase
  attr_accessor :order

  validates :order, presence: true

  record { 42 }

  success
  step :do_things

  def do_things
    raise "You shouldn't have did that!"
  end
end

# Test implementation of the UseCase which uses failure
class UseCaseTestImplFailure < Rails::UseCase
  attr_accessor :order

  validates :order, presence: true

  failure :foobar, message: 'test'
  step :do_things

  def do_things
    raise "You shouldn't have did that!"
  end
end

describe Rails::UseCase do
  let(:order) { Order.new }

  it 'can be called via call() or perform()' do
    expect(UseCaseTestImpl.call(order: order).record).to eq(order)
    expect(UseCaseTestImpl.perform(order: order).record).to eq(order)
  end

  it 'runs the steps' do
    expect_any_instance_of(UseCaseTestImpl).to \
      receive(:do_things).and_call_original

    expect_any_instance_of(Order).to \
      receive(:bar).and_call_original

    expect_any_instance_of(Order).to \
      receive(:foo).and_call_original

    UseCaseTestImpl.call order: order
  end

  it 'returns a Rails::UseCase::Outcome instance' do
    expect(UseCaseTestImpl.call(order: order)).to be_an(Rails::UseCase::Outcome)
  end

  it 'includes the behavior module' do
    expect(UseCaseTestImpl.new).to respond_to(:method_from_behavior)
  end

  context 'when successful' do
    it 'returns a Rails::UseCase::Outcome with success = true' do
      outcome = UseCaseTestImpl.call(order: order)
      expect(outcome).to be_success
      expect(outcome).not_to be_failed
      expect(outcome.code).to eq(:success)
    end
  end

  context 'when not successful' do
    it 'returns a Rails::UseCase::Outcome with success = false' do
      outcome = UseCaseTestImplFail.call(order: order)
      expect(outcome).to be_failed

      expect(outcome.code).to eq(:step_false)
      expect(outcome.message).to eq("Step 'do_things' returned false")

      expect(outcome.exception).to be_a(Rails::UseCase::Error)
    end

    it 'allows to set code and message' do
      outcome = UseCaseTestImplFail2.call(order: order)
      expect(outcome).to be_failed

      expect(outcome.code).to eq(:foobar)
      expect(outcome.message).to eq('Something went wrong')

      expect(outcome.exception).to be_a(Rails::UseCase::Error)
    end
  end

  it 'can skip steps via if/unless' do
    expect_any_instance_of(UseCaseTestImplSkipIf).not_to \
      receive(:dont_do_this)

    expect_any_instance_of(UseCaseTestImplSkipUnless).not_to \
      receive(:dont_do_this)

    UseCaseTestImplSkipIf.call(order: order)
    UseCaseTestImplSkipUnless.call(order: order)
  end

  it 'can have a success step' do
    expect_any_instance_of(UseCaseTestImplSuccess).not_to \
      receive(:do_things)

    expect(UseCaseTestImplSuccess.call(order: order)).to be_success
  end

  it 'can have a record definition with a symbol' do
    outcome = UseCaseTestImpl.call(order: order)
    expect(outcome).to be_success
    expect(outcome.record).to eq(order)
  end

  it 'can have a record definition with a block' do
    outcome = UseCaseTestImplSuccess.call(order: order)
    expect(outcome).to be_success
    expect(outcome.record).to eq(42)
  end

  it 'can have a failure step' do
    expect_any_instance_of(UseCaseTestImplFailure).not_to \
      receive(:do_things)

    outcome = UseCaseTestImplFailure.call(order: order)

    expect(outcome).to be_failed

    expect(outcome.code).to eq(:foobar)
    expect(outcome.message).to eq('test')

    expect(outcome.exception).to be_a(Rails::UseCase::Error)
  end

  describe '#break_when_invalid!' do
    context 'when invalid' do
      it 'raises an error' do
        use_case = UseCaseTestImpl.new
        use_case.order = nil
        expect { use_case.break_when_invalid! }.to raise_error(Rails::UseCase::Error)
      end
    end

    context 'when valid' do
      it 'returns true' do
        use_case = UseCaseTestImpl.new
        use_case.order = order
        expect(use_case.break_when_invalid!).to eq(true)
      end
    end
  end

  describe '#save' do
    it 'saves the record' do
      use_case = UseCaseTestImpl.new
      use_case.order = order
      use_case.send(:save!, order)
      expect(order).not_to be_new_record
    end

    context 'when record not valid' do
      it 'raises a UseCase::Error' do
        allow(order).to receive(:save).and_return(false)

        use_case = nil

        expect do
          use_case = UseCaseTestImpl.new
          use_case.order = order
          use_case.send(:save!, order)
        end.to raise_error(Rails::UseCase::Error)

        expect(order).to be_new_record
        expect(use_case.errors[:order]).to be_present
        expect(use_case.errors.full_messages).to eq(
          ['Order ']
        )
      end
    end
  end
end
