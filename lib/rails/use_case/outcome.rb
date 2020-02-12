# frozen_string_literal: true

module Rails
  class UseCase
    # Outcome of a UseCase
    class Outcome
      attr_reader :success, :errors, :record, :exception

      # Constructor.
      # @param success [Boolean] Wether the UseCase was successful.
      # @param errors [Array|nil] ActiveModel::Validations error.
      # @param record [ApplicationRecord|nil] The main record of the use case.
      # @param exception [Rails::UseCase::Error|nil] The error which was raised.
      def initialize(success:, errors: nil, record: nil, exception: nil)
        @success = success
        @errors = errors
        @record = record
        @exception = exception
      end


      # @return [Boolean] Whether the UseCase was successful.
      def success?
        @success
      end


      # @return [Boolean] Whether the UseCase failed.
      def failed?
        !@success
      end
    end
  end
end
