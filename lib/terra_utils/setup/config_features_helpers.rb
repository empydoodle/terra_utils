#!/usr/bin/env ruby
# frozen_string_literal: true

module TerraUtils
  module Setup
    # Collect helpers for features config
    module ConfigFeaturesHelpers
      FEATURES_SCHEMA_PATH = %w[features base.json].freeze

      def setup_feature_config_files(ind: 1, **options)
        fetch_features_to_configure.each do |project, features|
          next if features.empty?

          header_("PROJECT FEATURES (#{project})", ind)
          say_("Generating features configuration for #{project} project scope...", ind)
          features.each do |schema|
            header_(["#{schema.fetch(:nice_name).upcase} (#{project})", schema.fetch(:description)], ind + 1)
            setup_config_file(schema, project: project, ind: ind + 1, **options)
          end
        end
      end

      def fetch_features_to_configure
        fetch_base_config(:projects_settings).map do |project, config|
          next nil unless config.fetch(:features, nil)

          features = config.fetch(:features).select { |_, cfg| cfg.fetch(:enabled, false) }
          [project, merge_features_config(features)]
        end.compact.to_h
      end

      def merge_features_config(features_hash)
        schemas = fetch_schema(*FEATURES_SCHEMA_PATH)
        features_hash.map do |name, project_config|
          config = schemas.find { |s| s.fetch(:name).to_sym == name }
          next nil unless config.fetch(:config).keys.any? { |k| k == :config_file }

          config.fetch(:config).merge!(project_config)
          config
        end.compact
      end

      def generate_version_enforcement_config(schema:, project: :global, ind: 3)
        unless feature_loaded?('TerraVersions')
          require File.join(__dir__, 'config_features_helpers', 'terra_versions.rb')
          extend TerraVersions
        end
        setup_terra_versions_config(project, ind: ind)
      end

      def generate_environment_variable_auto_fill_config(schema:, project: :global, ind: 3)
        unless feature_loaded?('EnvAutoFillHelpers')
          require File.join(__dir__, 'config_features_helpers', 'env_auto_fill.rb')
          extend EnvAutoFill
        end
        setup_env_auto_fill_config(project, ind: ind)
      end

      def feature_loaded?(lib)
        singleton_class.ancestors.include?(self.class.const_get(lib))
      rescue NameError
        # uninitialized constant means library is not loaded
        false
      end
    end
  end
end
