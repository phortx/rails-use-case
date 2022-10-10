# frozen_string_literal: true

require 'active_model'
require 'rails/use_case/outcome'

module Rails
  # UseCase. See README.
  class UseCase
    include Callable
    include ActiveModel::Validations

    attr_reader :record

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
    #
    # @param name [Symbol]
    # @param options [Hash]
    def self.step(name = :inline, options = {}, &block)
      @steps ||= []

      if block_given?
        options[:do] = block
        name = :inline
      end

      @steps << { name: name.to_sym, options: options }
    end


    def self.success(options = {})
      step :success, options
    end


    def self.failure(code = nil, options = {})
      options[:code] = code || options[:code] || :failure
      step :failure, options
    end


    # DSL to include a behavior.
    # @param mod [Module]
    def self.with(mod)
      include mod
    end


    # DSL to set the record source.
    # @param [Symbol|nil] Name of the param.
    # @yields
    def self.record(param = nil, &block)
      block = -> { send(param.to_sym) } unless block_given?

      define_method(:determine_record, &block)
    end


    # Will run the steps of the use case.
    def process
      @record = determine_record if respond_to?(:determine_record)
      run_steps
    end


    def run_steps
      self.class.steps.each do |step|
        # Check wether to skip when :if or :unless are set.
        next if skip_step?(step)

        opts = step[:options]
        name = step[:name]

        # Handle failure and success steps.
        return true if name == :success

        fail!(code: opts[:code], message: opts[:message]) if name == :failure

        # Run the lambda, when :do is set. Otherwise call the method.
        next if opts[:do] ? instance_exec(&opts[:do]) : send(name)

        # result is false, so we have a failure.
        fail! code: :step_false, message: "Step '#{name}' returned false"
      end
    end


    def fail!(code: nil, message: 'Failed')
      @error_code = code
      raise UseCase::Error, message
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

      fail! code: :validation_failed, message: errors.full_messages.join(', ')
    end


    # Saves the a ActiveRecord object. When the object can't be saved, the
    # validation errors are pushed into the UseCase errors array and then
    # a UseCase::Error is raised.
    # @param record [ApplicationModel] Record to save.
    # @raises [UseCase::Error] When record can't be saved.
    private def save!(record = nil)
      if record.nil?
        record = @record
        name = :record
      else
        name = record.model_name.singular
      end

      return false unless record
      return true if record.save

      errors.add(
        name,
        :invalid,
        message: record.errors.full_messages.join(', ')
      )

      fail! code: :save_failed, message: errors.full_messages.join(', ')
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
        exception: error,
        message: error.message,
        code: @error_code
      )
    end
  end
end
