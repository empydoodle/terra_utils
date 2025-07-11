#!/usr/bin/env ruby
# frozen_string_literal: true

module TerraUtils
  module Setup
    module ConfigBaseHelpers
      # Helpers to populate projects_settings in main config
      module Projects
        SCHEMA_PATH               = %w[projects.json].freeze
        IAC_FRAMEWORK_OPTIONS     = %i[terraform opentofu terragrunt].freeze
        PROVIDER_PLATFORM_OPTIONS = %i[linux_amd64 linux_arm64 darwin_amd64 darwin_arm64 windows_amd64].freeze

        def generate_project_config(project, ind: 3)
          project_settings_header(project, ind)
          config = {}
          fetch_schema(*SCHEMA_PATH).each do |schema|
            next unless override_setting_for_project?(project, schema.fetch(:nice_name), ind: ind)

            config[schema.fetch(:name).to_sym] = setup_from_schema(schema, project: project, ind: ind + 1)
          end
          config
        end

        def project_settings_header(project, ind = nil)
          header_txt = []
          if project == :global
            header_txt.push('GLOBAL PROJECT SETTINGS',
                            'Configure settings to apply by default.',
                            '(Per-project configurations can be generated in later steps).')
          else
            header_txt.push("PROJECT SETTINGS (#{project})",
                            "Configure settings for the '#{project} project to override the global settings")
          end
          header_(header_txt.flatten, ind || 3)
        end

        def override_setting_for_project?(project, setting, ind: 3)
          return true if project.to_sym == :global

          prompt = "Create '#{setting}' config override for project '#{project}'?"
          user_switch_prompt(prompt_override: prompt, ind: ind, bold: false)
        end

        def setup_iac_framework(ind: 3, **)
          args = { options: IAC_FRAMEWORK_OPTIONS, single: true, with_custom: false }
          user_config_options(ref: 'infrastructure-as-code framework', **args, ind: ind)
        end

        def setup_provider_platforms(ind: 3, **)
          args = { ref: 'provider platform', options: PROVIDER_PLATFORM_OPTIONS, allow_empty: true }
          user_config_options(**args, ind: ind)
        end

        def setup_directory_structure(schema:, ind: 3, **)
          info_(schema.fetch(:info), ind)
          hint_('HINT: Speed up this step by entering /-separated values, e.g. client/env/namespace/module', ind)
          args = { prompt_eg: 'e.g. module, env', indent_results: true, delimiter: '/', dir_tree: true }
          user_config_options(ref: 'directory scope', **args, ind: ind)
        end

        def setup_features(project:, ind: 3, **)
          generate_project_features_config(project, ind: ind)
        end
      end
    end
  end
end
