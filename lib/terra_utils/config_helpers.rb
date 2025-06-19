#!/usr/bin/env ruby
# frozen_string_literal: true

module TerraUtils
  # Helper methods for configuration management
  module ConfigHelpers

    def parse_config(config_file = nil)
      parse_json_file(config_file || DEFAULT_CONFIG_FILE)
    end

    def fetch_config(key)
      @config.fetch(key.to_sym)
    rescue KeyError => e
      raise ConfigError, "Unable to fetch config from key '#{key.inspect}'. Error: #{e.message}"
    end

    def list_project_configurations
      fetch_config(:projects_settings).keys
    end

    def current_project_configured?
      list_project_configurations.include?(@project.to_sym)
    end

    def fetch_project_config(project = nil)
      project ||= current_project_configured? ? @project.to_sym : :global
      fetch_config(:projects_settings).fetch(project)
    rescue KeyError, ConfigError => e
      raise ConfigError, "Unable to fetch project settings for project '#{project.inspect}'. Error: #{e.message}"
    end

    def global_project_config
      fetch_project_config(:global)
    rescue KeyError, ConfigError => e
      raise ConfigError, "Unable to fetch global project settings. Error: #{e.message}"
    end

    def parse_project_config
      # Merge global project config with project-specific config if available
      return global_project_config unless current_project_configured?

      global         = global_project_config
      project_config = fetch_project_config
      global.each_key.map do |config_key|
        if global[config_key].is_a?(Hash)
          [config_key, global[config_key].merge(project_config.fetch(config_key, {}))]
        else
          [config_key, project_config.fetch(config_key, global[config_key])]
        end
      end.to_h
    end

    def project_features_config
      parse_project_config.fetch(:features)
    rescue KeyError => e
      raise ConfigError, "Unable to fetch features from project config! Error: #{e.message}"
    end

    def list_enabled_features
      features = project_features_config
      # Override project config-enabled features with CLI options
      features.each_key { |k| features[k][:enabled] = @options[k] unless @options[k].nil? }
      # List all remaining enabled features
      features.select { |_, v| v.fetch(:enabled, false) }.keys
    end

    def validate_features
      # Enable configured features based on project config
      enabled = list_enabled_features
      enable_aliases if enabled.include?(:command_aliases)
      enable_backend_auto_auth if enabled.include?(:state_backend_auto_auth)
      enable_env_auto_fill if enabled.include?(:environment_variable_auto_fill)
    end
  end
end
