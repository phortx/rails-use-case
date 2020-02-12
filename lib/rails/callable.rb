# frozen_string_literal: true

require 'active_support/concern'

module Rails
  # Simple module to add a static call method to a class.
  module Callable
    extend ActiveSupport::Concern

    class_methods do
      def call(*args)
        new.call(*args)
      end

      alias_method :perform, :call
    end


    # @abstract
    def call(*_args)
      raise NotImplementedError
    end
  end
end
