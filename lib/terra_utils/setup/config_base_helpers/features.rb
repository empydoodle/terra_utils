#!/usr/bin/env ruby
# frozen_string_literal: true

module TerraUtils
  module Setup
    module ConfigBaseHelpers
      # Helpers to populate project features in base config
      module Features
        SCHEMA_PATH = %w[features base.json].freeze

        def generate_project_features_config(project, ind: 3)
          config = {}
          fetch_schema(*SCHEMA_PATH).each do |schema|
            next unless override_setting_for_project?(project, schema.fetch(:nice_name), ind: ind)

            args = { method: :generate_project_feature_config, schema: schema }
            config[schema.fetch(:name).to_sym] = setup_from_schema(schema, **args, ind: ind + 1)
          end
          config
        end

        def generate_project_feature_config(schema:, ind: 4)
          feature_enabled = user_switch_prompt(prompt_ref: schema.fetch(:nice_name), ind: ind)
          feature_config  = project_feature_config_values(schema, feature_enabled: feature_enabled, ind: ind)
          { enabled: feature_enabled }.merge(feature_config)
        end

        def project_feature_config_values(schema, feature_enabled: true, ind: 4)
          schema.fetch(:config).reject { |k, _| k.to_s.include?('template') }.map do |key, default|
            next [key, nil] unless feature_enabled # null output for global

            prompt   = "Please enter a #{key.to_s.gsub('_', ' ')} for #{schema.fetch(:nice_name)}"
            default  = File.join(@config_dir, default) if key.match(/(file|path)/)
            [key, user_option_prompt(prompt_override: prompt, default: default, ind: ind)]
          end.to_h
        end
      end
    end
  end
end
