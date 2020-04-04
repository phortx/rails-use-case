# frozen_string_literal: true

require 'spec_helper'
require 'rails_use_case'
require 'fileutils'

# Test implementation of a Service
class TestService < Rails::Service
  attr_accessor :something

  def initialize
    super 'test'
  end

  def call(something:)
    something
  end
end

describe Rails::Service do
  before do
    FakeFS.activate!
    FileUtils.mkdir_p 'config/services'
    FileUtils.mkdir_p 'log/services'
    FileUtils.touch 'config/services/shared.yml'
    allow(Rails).to receive(:root).and_return(Pathname.new('.'))
  end

  after do
    FakeFS.deactivate!
  end

  it 'can be called via call() or perform()' do
    expect(TestService.call(something: 42)).to eq(42)
    expect(TestService.perform(something: 'nothing')).to eq('nothing')
  end

  describe 'logging' do
    it 'logs to dedicated file' do
      path = Rails.root.join('log', 'services', 'test.log').to_s

      allow(Logger).to receive(:new)
      TestService.call something: 1
      expect(Logger).to have_received(:new).with(path)
    end

    context 'when is SERVICE_LOGGER_STDOUT set' do
      it 'logs to STDOUT' do
        ENV['SERVICE_LOGGER_STDOUT'] = 'true'

        allow(Logger).to receive(:new).and_call_original
        TestService.call something: 1
        expect(Logger).to have_received(:new).with(STDOUT)

        ENV['SERVICE_LOGGER_STDOUT'] = nil
      end
    end
  end
end
