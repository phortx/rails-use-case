# frozen_string_literal: true

require 'spec_helper'
require 'rails_use_case'

# Test implementation of Callable without call method
class CallableImplBad
  include ::Rails::Callable
end

# Test implementation of Callable without call method
class CallableImplGood
  include ::Rails::Callable

  def call(*_args)
    true
  end
end


describe Rails::Callable do
  it 'has a call method' do
    expect(CallableImplGood).to respond_to(:call)
  end

  it 'has a perform method' do
    expect(CallableImplGood).to respond_to(:perform)
  end

  it 'has to implement the call method' do
    expect(CallableImplGood.call).to be_truthy
    expect { CallableImplBad.call }.to raise_error(NotImplementedError)
  end
end
