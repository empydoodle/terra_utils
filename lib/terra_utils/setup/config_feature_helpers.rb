#!/usr/bin/env ruby
# frozen_string_literal: true

module TerraUtils
  module Setup
    # Helpers to populate project features config
    module ConfigFeatureHelpers
      def setup_feature_environment_variable_auto_fill(project: :global, ind: 3)
        require File.join(__dir__, 'config_feature_helpers', 'env_auto_fill_helpers.rb')
        extend EnvAutoFillHelpers
        setup_env_auto_fill_config(project, ind: ind)
      end

      def setup_project_feature_config(project, feature_config, ind: 3)
        feature_config_file = feature_config.dig(:config, :config_file)
        return false unless feature_config_file

        method = "setup_feature_#{feature_config.fetch(:name)}".to_sym
        args   = { name: name, file: feature_config_file, method: method, ind: ind, project: project }

        setup_config_file(**args, force_config_template: feature_config.dig(:config, :force_config_template))
      end

      def setup_project_features_config(project, features, ind: 3)
        return if features.empty?

        features.each do |name, config|
          next unless config.keys.include?('config_file')

          feat_config = T_U_FEATURES.dup.find { |feat| feat.fetch(:name) == name }
          feat_config.fetch(:config).merge!(config)
          setup_project_feature_config(project, feat_config, ind: ind)
        end
      end

      def fetch_enabled_features_by_project
        fetch_base_config.fetch(:projects_settings).map do |project, project_config|
          features = project_config.fetch(:features)
          [
            project,
            features.select { |_, config| config.fetch(:enabled, false) }
          ]
        end.to_h
      end

      def setup_projects_features_config(ind: 2)
        fetch_enabled_features_by_project.each do |project, features|
          say_("Generating features configuration for #{project} project scope...", ind)
          setup_project_features_config(project, features, ind: ind + 1)
        end
      end

      def fetch_base_project_feature_config(project, feature)
        fetch_base_config(path: [:projects_settings, project.to_sym, :features, feature.to_sym])
      rescue KeyError, NoMethodError
        # default to global config
        fetch_base_config(path: [:projects_settings, :global, :features, feature.to_sym])
      end
    end
  end
end
