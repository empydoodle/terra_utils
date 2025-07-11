#!/usr/bin/env ruby
# frozen_string_literal: true

module TerraUtils
  # Helper methods for configuration management
  module ConfigHelpers

    def parse_config(config_file = nil, symbol_keys: true)
      parse_json_file(config_file || DEFAULT_CONFIG_FILE, symbols: symbol_keys)
    end

    def fetch_from_config(*path, config_obj: nil)
      config = (config_obj || @config).dup
      key    = nil
      path.flatten.each do |e|
        key    = e.to_sym
        config = config.fetch(key)
      end
      config
    rescue KeyError => e
      raise ConfigError, "Unable to fetch config from key '#{key.inspect}' (from path #{path}): #{e.message}"
    end

    def fetch_config(*path)
      fetch_from_config(*path)
    end

    def list_project_configurations
      fetch_config(:projects_settings).keys
    end

    def current_project_configured?
      list_project_configurations.include?(@project.to_sym)
    end

    def project_config(project = nil)
      project ||= current_project_configured? ? @project.to_sym : :global
      fetch_config(:projects_settings, project)
    rescue KeyError, ConfigError => e
      raise ConfigError, "Unable to fetch project settings for project '#{project.inspect}'. Error: #{e.message}"
    end

    def global_project_config
      fetch_config(:projects_settings, :global)
    rescue KeyError, ConfigError => e
      raise ConfigError, "Unable to fetch global project settings. Error: #{e.message}"
    end

    def parse_project_config
      # Merge global project config with project-specific config if available
      return global_project_config unless current_project_configured?

      global  = global_project_config
      project = project_config
      global.each_key.map do |config_key|
        if global[config_key].is_a?(Hash)
          [config_key, global[config_key].merge(project.fetch(config_key, {}))]
        else
          [config_key, project.fetch(config_key, global[config_key])]
        end
      end.to_h
    end

    def fetch_project_config(*path)
      @project_config ||= parse_project_config
      fetch_from_config(*path, config_obj: @project_config)
    rescue ConfigError => e
      raise ConfigError, "Project (#{@project}) config lookup failed: #{e.message}"
    end

    def project_features_config
      fetch_project_config(:features)
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
      enabled.each do |feature|
        public_send("enable_feature_#{feature}".to_sym)
      end
    end
  end
end
