#!/usr/bin/env
# frozen_string_literal: true

require 'mkmf'
require 'json'
require 'yaml'

require_relative '../terra_utils'

module TerraUtils
  # Methods for extracting and collating API key env vars
  module EnvAutoFill
    def env_autofill_project_config
      project_features_config.fetch(:environment_variable_autofill)
    rescue KeyError => e
      err = "Unable to fetch Environment Variable Autofill feature config from project config! Error: #{e.message}"
      raise ConfigError, err
    end

    def env_autofill_config_file
      @env_autofill_config_path || env_autofill_project_config.fetch(:config_file)
    end

    def parse_env_autofill_config
      # Specifically don't convert to symbols here
      enable_onepass_if_installed
      @env_autofill_config = parse_json_file(env_autofill_config_file)
    rescue JSON::ParserError => e
      raise ConfigError, "Failed to parse env_autofill config: #{env_autofill_config_file}. Error: #{e.message}"
    end

    def autofill_env?
      [ # Only use for accepted terragrunt commands
        @env_autofill_config.fetch(:valid_terragrunt_commands).any? { |cmd| @terra_subcmd == cmd }
      ].flatten.uniq == [true]
    end

    def generate_env_vars
      @env_autofill_config.fetch(:variables_config).map do |cfg|
        log_debug("Fetching environment variables: #{cfg.fetch(:environment_variables)}") if @debug
        scope  = @scope.fetch(cfg.fetch(:config_scope, nil), :glob).to_sym
        config = select_service_config(cfg.fetch(:service_instance_config), scope)
        cfg.fetch(:environment_variables).flat_map do |var|
          [var, fetch_service_config(**config)].join('=')
        end
      end.join(' ')
    end

    module_function

    def enable_onepass_if_installed
      @onepass_enabled = false
      return false unless system('which op 1> /dev/null')

      require_relative '../one_pass_hax'
      extend OnePassHax
      @onepass_enabled = true
      true
    end

    def op_path?(path)
      path.start_with?('op://')
    end

    def select_service_config(config_path_opts, scope)
      config_path_opts.fetch(scope, nil) || config_path_opts.fetch(:glob)
    end

    def read_config_ref(config_ref)
      if op_path?(config_ref)
        raise ConfigError, "Cannot load secret from #{op_path} - 1Password not installed" unless @onepass_enabled

        fetch_op_secret(config_ref)
      else
        File.read(config_ref)
      end
    end

    def parse_config_ref(ref:, format:)
      case format.downcase.to_sym
      when :json
        JSON.parse(read_config_ref(ref))
      when :yaml
        YAML.load(read_config_ref(ref))
      when :txt
        read_config_ref(ref).strip
      when :string
        ref
      end
    end

    def valid_config_subdivisions?(config_subs)
      config_subs.is_a?(Array) && !config_subs.empty?
    end

    def fetch_subdivision_config(service_config, subs)
      service_config.dig(*subs.map { |div| @scope.fetch(div, nil) }.compact)
    rescue NoMethodError => e
      err = "No value configured for #{subs.inspect} against service config:\n#{service_config.inspect}\nError: #{e}"
      raise ConfigError, err
    end

    def fetch_service_config(ref:, format:, config_subdivisions: nil, key: nil)
      config = parse_config_ref(ref: ref, format: format)
      config = config.fetch(key) if key && %i[json yaml].include?(format.downcase.to_sym)
      return config unless valid_config_subdivisions?(config_subdivisions)

      fetch_subdivision_config(config, config_subdivisions)
    end
  end
end
