#!/usr/bin/env ruby
# frozen_string_literal: true

module TerraUtils
  module Setup
    # Helpers to populate project features config
    module ConfigBaseFeatureHelpers
      def feature_config_target_setup(config:, feature_enabled: true, ind: 2)
        # Pass feature hash of feature from T_U_FEATURES
        config.fetch(:config).keys.map do |key|
          next [key.to_s, nil] unless feature_enabled

          default  = config.fetch(:config).fetch(key)
          default  = File.join(@config_dir, default) if key.match(/(file|path)/)
          prompt   = "Please enter a #{key.to_s.gsub('_', ' ')} for #{config.fetch(:name)}"
          value    = user_option_prompt(prompt_override: prompt, default: default, ind: ind)
          [key.to_s, value.empty? ? default : value]
        end.to_h
      end

      def set_project_feature(config:, ind: 2)
        # Pass feature hash of feature from T_U_FEATURES
        header = ["FEATURE: #{config.fetch(:nice_name).upcase}", config.fetch(:description)]
        header_(header, ind)
        feature_enabled = user_switch_prompt(prompt_ref: config.fetch(:nice_name), ind: ind)
        feature_config  = feature_config_target_setup(config: config, feature_enabled: feature_enabled, ind: ind)
        { 'enabled' => feature_enabled }.merge(feature_config)
      end

      def enable_feature(name:, ind: 3)
        feature_setup = T_U_FEATURES.find { |e| e[:name] == name }
        raise ArgumentError, "'#{name}' not found in #{File.join(T_U_CONFIG_DIR, 'features.json')}" unless feature_setup

        set_project_feature(config: feature_setup, ind: ind)
      rescue ArgumentError => e
        error_("#{e.message} - skipping feature setup", ind)
        nil
      end

      def setup_project_features(project, ind: 2)
        header_(["FEATURES [#{project}]", "Enable features for the #{project} project scope."], ind, margin: 13)
        T_U_FEATURES.map do |feature|
          name = feature.fetch(:name)
          if override_setting_for_project?(project: project, setting: "feature:#{name}", ind: ind)
            [name, enable_feature(name: name, ind: ind + 1)]
          end
        end.compact.to_h
      end
    end
  end
end
