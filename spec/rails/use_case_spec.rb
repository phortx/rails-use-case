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
end

# Test implementation of the UseCase
class UseCaseTestImpl < Rails::UseCase
  attr_accessor :order

  validates :order, presence: true

  step :do_things

  def do_things
    @record = order
  end
end

# Test implementation of the UseCase which fails
class UseCaseTestImplFail < Rails::UseCase
  attr_accessor :order

  validates :order, presence: true

  step :do_things

  def do_things
    @record = order
    false
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
  end

  def dont_do_this
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

    UseCaseTestImpl.call order: order
  end

  it 'returns a Rails::UseCase::Outcome instance' do
    expect(UseCaseTestImpl.call(order: order)).to be_an(Rails::UseCase::Outcome)
  end

  context 'when successful' do
    it 'returns a Rails::UseCase::Outcome with success = true' do
      expect(UseCaseTestImpl.call(order: order).success?).to be_truthy
      expect(UseCaseTestImpl.call(order: order).failed?).to be_falsey
    end
  end

  context 'when not successful' do
    it 'returns a Rails::UseCase::Outcome with success = false' do
      expect(UseCaseTestImplFail.call(order: order).success?).to be_falsey
      expect(UseCaseTestImplFail.call(order: order).failed?).to be_truthy
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
        allow_any_instance_of(Order).to receive(:save).and_return(false)

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
