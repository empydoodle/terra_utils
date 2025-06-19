#!/usr/bin/env ruby
# frozen_string_literal: true

module TerraUtils
  module Setup
    module ConfigFeatureHelpers
      # Helpers for Environment Variables Auto Fill setup
      module EnvAutoFillHelpers
        DEFAULT_VALID_COMMANDS = %w[plan apply destroy import].freeze
        VALUE_CONFIG_FORMATS   = %w[JSON YAML TXT String].freeze

        def eaf_valid_commands(ind: 3)
          header = [
            'VALID COMMANDS',
            'Set the Terraform/Terragrunt commands that will trigger environment variable auto-filling.'
          ]
          header_(header, ind)
          user_config_options(ref: 'valid_commands', default: DEFAULT_VALID_COMMANDS, with_custom: true, ind: ind)
        end

        def prompt_eaf_target_env_vars(env_vars: [], ind: 4)
          header_(['TARGET ENVIRONMENT VARIABLES', 'Set the environment variable(s) to auto-fill with this config instance.'], ind)
          say_('HINT: Speed up this step by entering comma-separated values, e.g. PROVIDER_TOKEN,PROVIDER_USER_TOKEN', ind, :blue)
          args = { prompt_ref: 'environment variable', prompt_eg: 'PROVIDER_API_KEY', escape: !vars.empty? }
          vars = user_option_prompt(ind: ind, **args).split(',')
          env_vars.push(vars.reject(&:empty?)).flatten!
          if prompt_additional_configs(ref: 'environment variable', selected_options: env_vars, ind: ind)
            prompt_target_env_vars(env_vars: env_vars, ind: ind)
          end
          env_vars
        end

        def prompt_eaf_config_scope(project_dir_structure, ind: 4)
          header_(['CONFIG SCOPE', 'Select the scope which decides the source of environment variables.'], ind)
          explanation = [
            'TerraUtils selects the source for environment variable values based on the chosen scope.',
            'This scope identifier resolves to the value of the corresponding scope of the project directory structure.',
            'Using a "nil" scope is valid if the same variable needs to be applied regardless of scope.'
          ]
          info_(explanation, ind)

          say_('HINT: Choose "X" option to specify no config scope (i.e. just use a global scope)', :blue)
          config_scope = select_from_options(scopes, ind: ind, with_custom: false, single: true, leading_br: false)
          config_scope.empty? ? nil : config_scope.first
        end

        def fetch_path_eaf_value_config_keys_options(path, dir_level)
          return nil unless Dir.exist?(path)

          entries = Dir.glob(File.join(path, *Array.new(dir_level + 1, '*'))).select { |e| File.directory?(e) }
          entries.map { |e| File.basename(e) }
        end

        def fetch_project_eaf_value_config_keys_options(project, config_scope)
          dir_level = fetch_base_project_setting(project.to_sym, :directory_structure).index(config_scope)
          fetch_base_config(:projects_dirs).map do |dir|
            projects = project.to_sym == :global ? fetch_project_options_from_project_dir(dir) : [project.to_s]
            projects.map do |p|
              fetch_path_eaf_value_config_keys_options(File.join(dir, p), dir_level)
            end.compact
          end.flatten.uniq.sort
        end

        def prompt_eaf_value_config_keys(project, config_scope, ind: 4)
          header_(['VALUE CONFIGURATIONS', "Configure the value sources per '#{config_scope}'."], ind)
          explanation = [
            "INFO: Provide the values of the chosen scope ('#{config_scope}') that require different value sources",
            '      These values must align with the names of the directories in the scope of the project.',
            '        e.g. if scope is "environment", values could be ["production", "staging", "testing"]'
          ]
          info_(explanation, ind)
          defaults = fetch_project_eaf_value_config_keys_options(project, config_scope)
          keys     = user_config_options(ref: "'#{config_scope}'", defaults: defaults, with_custom: true, ind: 2)
          no_?("Add a global option for scope ('#{config_scope}')?", ind) ? keys : keys.unshift('global')
        end

        def eaf_value_config_ref(config_scope, scope_value, ind: 5)

        end

        def eaf_value_config_format(config_scope, scope_value, ind: 5)
        end

        def eaf_value_config_key(config_scope, scope_value, ind: 5)
        end

        def eaf_value_config_subdivisions(config_scope, scope_value, ind: 5)
        end

        def additional_eaf_scope_value_config(config_scope, scope_value, config_format, ind: 5)
          unless %w[JSON YAML].include?(config_format)
            return config_scope.to_sym == :global ? %i[key config_subdivisions].map { |k| [k, nil] }.to_h : nil
          end

          {
            key: eaf_value_config_key(config_scope, scope_value, ind: ind),
            config_subdivisions: eaf_value_config_subdivisions(config_scope, scope_value, ind: ind)
          }
        end

        def generate_eaf_scope_value_config(config_scope, scope_value, ind: 4)
          header_(["VALUE CONFIG (#{scope_value})", "Configure the '#{scope_value}' value source for the #{config_scope} scope."], ind)
          explanation = [
            'TerraUtils selects the source for environment variable values based on the chosen scope.',
            'This scope identifier resolves to the value of the corresponding scope of the project directory structure.',
            'Using a "nil" scope is valid if the same variable needs to be applied regardless of scope.'
          ]
          info_(explanation, ind)
          config = {
            ref: eaf_value_config_ref(config_scope, scope_value, ind: ind + 1),
            format: eaf_value_config_format(config_scope, scope_value, ind: ind + 1)
          }
          config.merge!(additional_eaf_scope_value_config(config_scope, scope_value, config.fetch(:format), ind: 5))
        end

        def initial_eaf_config(project_dir_structure, ind: 4)
          {
            environment_variables: prompt_eaf_target_env_vars(ind: ind),
            config_scope: prompt_eaf_config_scope(project_dir_structure, ind: ind),
            value_config: []
          }
        end

        def env_auto_fill_config_instance(project, ind: 3)
          header = [
            'ENVIRONMENT VARIABLE AUTO-FILL CONFIG INSTANCE',
            'Set up a new config instance for environment variable auto-fill.'
          ]
          header_(header, ind)
          config = initial_eaf_config(fetch_base_project_setting(project, :directory_structure).keys.map(&:to_s), ind: ind + 1)

          config_scope      = config.fetch(:config_scope)
          value_config_keys = config_scope.nil? ? ['global'] : prompt_eaf_value_config_keys(config_scope, ind: ind)

          #service_instance_config
          #  project
          #    ref
          #    format
          #    key
          #    subdivisions
        end


        def setup_env_auto_fill_config(project, ind: 3)
          config = { valid_commands: eaf_valid_commands(ind: ind), variables_config: [] }
        end
      end
    end
  end
end
