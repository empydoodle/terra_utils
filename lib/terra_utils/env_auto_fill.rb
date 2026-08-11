#!/usr/bin/env
# frozen_string_literal: true

require 'mkmf'
require 'json'
require 'yaml'

require_relative '../terra_utils'
require_relative 'secrets_helpers'

module TerraUtils
  # Methods for extracting and collating API key env vars
  module EnvAutoFill
    extend SecretsHelpers

    FEATURE_IDENT = :environment_variable_auto_fill

    def env_auto_fill_project_config
      project_features_config.fetch(FEATURE_IDENT)
    rescue KeyError => e
      err = "Unable to fetch Environment Variable Auto-Fill feature config from project config! Error: #{e.message}"
      raise ConfigError, err
    end

    def env_auto_fill_config_file
      @env_auto_fill_config_path || env_auto_fill_project_config.fetch(:config_file)
    end

    def parse_env_auto_fill_config
      # Specifically don't convert to symbols here
      enable_onepass_if_installed
      log_debug("Parsing feature config (#{FEATURE_IDENT}): #{env_auto_fill_config_file}")
      @env_auto_fill_config = parse_json_file(env_auto_fill_config_file)
    rescue JSON::ParserError => e
      raise ConfigError, "Failed to parse env_auto_fill config: #{env_auto_fill_config_file}. Error: #{e.message}"
    end

    def auto_fill_env?
      [ # Only use for accepted terragrunt commands
        @env_auto_fill_config.fetch(:valid_commands).any? { |cmd| @terra_subcmd == cmd }
      ].flatten.uniq == [true]
    end

    def generate_env_vars
      @env_auto_fill_config.fetch(:variables_config).map do |cfg|
        log_debug("Fetching environment variables: #{cfg.fetch(:environment_variables)}") if @debug
        scope  = @scope.fetch(cfg.fetch(:config_scope, nil), :global).to_sym
        config = select_value_config(cfg.fetch(:value_config), scope)
        cfg.fetch(:environment_variables).flat_map do |var|
          [var, fetch_value_config(**config)].join('=')
        end
      rescue NoMethodError
        log_debug("Unable to fetch environment variable config for entry (#{cfg.inspect}). Skipping...")
      end.join(' ')
    end

    module_function

    def select_value_config(config_path_opts, scope)
      config_path_opts.fetch(scope, nil) || config_path_opts.fetch(:global)
    end

    def read_config_ref(config_ref)
      if onepass_path?(config_ref)
        raise ConfigError, "Cannot load secret from #{config_ref} - 1Password not installed" unless onepass_enabled?

        fetch_op_secret(config_ref)
      elsif sops_enabled? && sops_encrypted?(config_ref)
        read_sops(config_ref)
      else
        File.read(config_ref)
      end
    end

    def parse_config_ref(ref:, format:)
      case format.downcase.to_sym
      when :json
        JSON.parse(read_config_ref(ref))
      when :yaml
        YAML.safe_load(read_config_ref(ref))
      when :txt
        read_config_ref(ref).strip
      when :string
        ref
      end
    end

    def valid_config_subdivisions?(config_subs)
      config_subs.is_a?(Array) && !config_subs.empty?
    end

    def fetch_subdivision_config(value_config, subs)
      value_config.dig(*subs.map { |div| @scope.fetch(div, nil) }.compact)
    rescue NoMethodError => e
      err = "No value configured for #{subs.inspect} against value config:\n#{value_config.inspect}\nError: #{e}"
      raise ConfigError, err
    end

    def fetch_value_config(ref:, format:, config_subdivisions: nil, key: nil)
      config = parse_config_ref(ref: ref, format: format)
      config = config.fetch(key) if key && %i[json yaml].include?(format.downcase.to_sym)
      return config unless valid_config_subdivisions?(config_subdivisions)

      fetch_subdivision_config(config, config_subdivisions)
    end
  end
end
