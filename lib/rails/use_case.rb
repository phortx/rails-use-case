# frozen_string_literal: true

require 'active_model/validations'
require 'rails/use_case/outcome'

module Rails
  class Rails::UseCase
    include Callable
    include ActiveModel::Validations

    class Error < StandardError; end

    class << self
      attr_reader :steps
    end


    # Will be called by Callable.call.
    # @param params [Hash] The arguments for the UseCase as Hash
    #                      so we can auto assign instance variables.
    def call(params)
      prepare params
      process

      successful_outcome
    rescue UseCase::Error => e
      failure_outcome e
    end


    # DSL to define a process step of the UseCase.
    # You can use if/unless with a lambda in the options
    # to conditionally skip the step.
    # @param name [Symbol]
    # @param options [Hash]
    def self.step(name, options = {})
      @steps ||= []
      @steps << { name: name.to_sym, options: options }
    end


    # Will run the steps of the use case.
    def process
      self.class.steps.each do |step|
        next if skip_step?(step)
        next if send(step[:name])

        raise UseCase::Error, "Step #{step[:name]} returned false"
      end
    end


    # Checks whether to skip a step.
    # @param step [Hash]
    def skip_step?(step)
      if step[:options][:if]
        proc = step[:options][:if]
        result = instance_exec(&proc)
        return true unless result
      end

      return false unless step[:options][:unless]

      proc = step[:options][:unless]
      result = instance_exec(&proc)
      return true if result
    end


    # Prepare step. Runs automatically before the UseCase process starts.
    # Sets all params as instance variables and then runs the validations.
    # @param params [Hash]
    def prepare(params)
      params.each do |key, value|
        instance_variable_set "@#{key}", value
      end

      break_when_invalid!
    end


    # @raises [UseCase::Error] When validations failed.
    def break_when_invalid!
      return true if valid?

      raise UseCase::Error, errors.full_messages.join(', ')
    end


    # Saves the a ActiveRecord object. When the object can't be saved, the
    # validation errors are pushed into the UseCase errors array and then
    # a UseCase::Error is raised.
    # @param record [ApplicationModel] Record to save.
    # @raises [UseCase::Error] When record can't be saved.
    private def save!(record = nil)
      record ||= @record

      return false unless record
      return true if record.save

      errors.add(
        record.model_name.singular,
        :invalid,
        message: record.errors.full_messages.join(', ')
      )

      raise UseCase::Error, "#{record.class.name} is not valid"
    end


    # @return [UseCase::Outcome] Successful outcome.
    private def successful_outcome
      Outcome.new(
        success: true,
        record: @record,
        errors: errors
      )
    end


    # @param error [StandardError]
    # @return [UseCase::Outcome] Failure outcome with exception set.
    private def failure_outcome(error)
      Outcome.new(
        success: false,
        record: @record,
        errors: errors,
        exception: error
      )
    end
  end
end
