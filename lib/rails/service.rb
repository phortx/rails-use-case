# frozen_string_literal: true

require 'fileutils'
require 'logger'

module Rails
  # Abstract base class for all 3rd party services
  #
  # Provides:
  #   - Configuration (automatically loaded from `config/services/[service_name].yml`, available as `config`)
  #   - Logging (to separate log file `log/services/[service_name].log`, call via `logger.info(msg)`)
  #   - Call style invocation (like `PDFGenerationService.(some, params)`)
  #
  # @example
  #   class Services::PDFGenerationService < Service
  #     def initialize
  #       super('pdf_generation')
  #     end
  #
  #     def call(action, *args)
  #        ... here happens the magic! ...
  #     end
  #   end
  #
  #   PDFGenerationService.(some, params)
  #
  # @abstract
  class Service
    include Rails::Callable

    attr_reader :logger, :service_name, :config

    # Constructor. Call this from the subclass with the service name, like `super 'pdf_generator'`.
    # After that you can access the config and logger.
    #
    # @param [String] service_name Name of the service, like 'pdf_generator'.
    # @raise [NotImplementedError] When this class is tried to be instantiated without subclass.
    #
    # @raise [RuntimeError] When no service_name is given
    def initialize(service_name = nil)
      raise NotImplementedError if self.class == Service
      raise 'Please provide a service name!' if service_name.nil?

      @service_name = service_name

      setup_logger
      setup_configuration
    end


    # Create the log file and sets @logger
    private def setup_logger
      if ENV['SERVICE_LOGGER_STDOUT']
        setup_stdout_logger
      else
        log_path = Rails.root.join('log', 'services')
        FileUtils.mkdir_p(log_path) unless Dir.exist?(log_path)

        log_file = log_path.join("#{@service_name}.log").to_s

        FileUtils.touch log_file
        @logger = Logger.new(log_file)
      end
    end


    # Will setup the logger for logging to STDOUT. This can be useful for
    # Heroku for example.
    private def setup_stdout_logger
      @logger = Logger.new(STDOUT)

      @logger.formatter = proc do |severity, datetime, progname, msg|
        msg = "[@service_name] #{msg}"
        original_formatter.call(severity, datetime, progname, msg.dump)
      end
    end


    # Loads the configuration for that service and saves it to @config
    # @raise [RuntimeError] When the config file doesn't exist
    private def setup_configuration
      shared_config_path = Rails.root.join('config', 'services', 'shared.yml')
      config_path = Rails.root.join('config', 'services', "#{@service_name}.yml")
      raise "Couldn't find the shared config file '#{shared_config_path}'." unless File.exist?(shared_config_path)

      shared_config = load_config_file(shared_config_path)

      if File.exist?(config_path)
        service_config = load_config_file(config_path) || {}
        @config = shared_config.merge(service_config)
      else
        @config = shared_config
      end
    end


    private def load_config_file(path)
      erb = File.read(path)
      yaml = ERB.new(erb).result.strip

      return {} if yaml.blank?

      YAML.safe_load(yaml) || {}
    end


    # Convenience method to get a secret. It looks for the key `services.<service_name>.<key>`
    private def secret(key)
      key = key.to_sym
      base = Rails.application.secrets.services[@service_name.to_sym]

      raise "No secrets entry found for 'services.#{@service_name}'" unless base
      raise "No secrets entry found for 'services.#{@service_name}.#{key}'" unless base[key]

      base[key]
    end


    # Abstract method for instance call. Implement this in the subclass!
    # @raise [NotImplementedError] When this is not overwritten in the subclass
    def call(options); end


    # Allows call syntax on class level: SomeService.(some, args)
    def self.call(*args)
      new.(*args)
    end

    # Allows to use rails view helpers
    def helpers
      ApplicationController.new.helpers
    end
  end
end
