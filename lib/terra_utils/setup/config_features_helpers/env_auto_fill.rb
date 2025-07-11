#!/usr/bin/env ruby
# frozen_string_literal: true

require 'yaml'

module TerraUtils
  module Setup
    module ConfigFeaturesHelpers
      # Helpers for Environment Variables Auto Fill setup
      module EnvAutoFill
        SCHEMA_PATH            = %w[features environment_variable_auto_fill].freeze
        SCHEMA_PATH_BASE       = SCHEMA_PATH.dup.push('base.json')
        SCHEMA_PATH_INSTANCE   = SCHEMA_PATH.dup.push('instance.json')
        SCHEMA_PATH_VALUES     = SCHEMA_PATH.dup.push('values.json')
        DEFAULT_VALID_COMMANDS = %w[plan apply destroy import].freeze
        VALUE_CONFIG_FORMATS   = %w[JSON YAML TXT String].freeze

        def setup_env_auto_fill_config(project, ind: 3)
          config = {}
          fetch_schema(*SCHEMA_PATH_BASE).each do |schema|
            config[schema.fetch(:name).to_sym] = setup_eaf_from_schema(schema, project, ind: ind, config: config)
          end
          config
        end

        def setup_eaf_from_schema(schema, project, ind: 3, config: {}, **args)
          schema[:name] = "eaf_#{schema.fetch(:name)}"
          setup_from_schema(schema, project: project, ind: ind, **config, **args)
        end

        def setup_eaf_valid_commands(ind: 3, **)
          user_config_options(ref: 'valid command', options: DEFAULT_VALID_COMMANDS, with_custom: true, ind: ind)
        end

        def setup_eaf_variables_config(project:, ind: 3, **)
          say_('Generating environment variable config instances...', ind)
          warn_('Each config instance will only read one value source', ind)
          config = [generate_eaf_config_instance(project, ind: ind + 1)]
          while yes_?('Create auto-fill config instance for new environment variable?', ind, :leading_br)
            config.push(generate_eaf_config_instance(project, ind: ind + 1))
          end
          config
        end

        def generate_eaf_config_instance(project, ind: 4)
          config = {}
          fetch_schema(*SCHEMA_PATH_INSTANCE).each do |schema|
            config[schema.fetch(:name).to_sym] = setup_eaf_from_schema(schema, project, config: config, ind: ind)
          end
          say_("Config instance created for environment variables #{config.fetch(:environment_variables)}!", ind, :green)
          config
        end

        def setup_eaf_environment_variables(ind: 4, **)
          hint_('HINT: Speed up this step by entering comma-separated values, e.g. PROVIDER_TOKEN,PROVIDER_USER_TOKEN', ind)
          args = { ref: 'config instance environment variable', prompt_eg: 'PROVIDER_API_KEY', delimiter: ',' }
          user_config_options(**args, ind: ind)
        end

        def setup_eaf_config_scope(project:, schema:, ind: 4, **)
          info_(schema.fetch(:info), ind)
          hint_([
                  "HINT: Choose \"#{TerraUtils::Setup::SetupHelpers::ESCAPE_STRING}\" option to specify no config scope",
                  '  (i.e. just use a global scope)'
                ], ind)
          args           = { ref: 'config instance scope', with_custom: false, single: true, allow_empty: true }
          args[:options] = fetch_base_project_setting(project.to_sym, :directory_structure).unshift('project')
          user_config_options(**args, ind: ind, leading_br: false)
        end

        def setup_eaf_value_config(project:, schema:, config_scope:, ind: 4, **)
          info_(schema.fetch(:info), ind)
          generate_eaf_value_config_keys(config_scope, project, ind: ind).map do |opt|
            header_("VALUE CONFIGURATION (#{[config_scope, opt].compact.join(' = ')})", ind)
            opt_config = {}
            fetch_schema(*SCHEMA_PATH_VALUES).each do |src_schema|
              args = { config_value: opt, ind: ind, config: opt_config }
              opt_config[src_schema.fetch(:name).to_sym] = setup_eaf_from_schema(src_schema, project, **args, ind: ind + 1)
            end
            [opt, opt_config]
          end.to_h
        end

        def generate_eaf_value_config_keys(config_scope, project, ind: 4)
          return [project.to_s] if project.to_s != 'global' && config_scope.to_s == 'project'

          if config_scope.nil?
            warn_('No config scope selected for this config instance - using global scope.', ind)
            ['global']
          else
            dir_level = fetch_base_project_setting(project.to_sym, :directory_structure).index(config_scope) # will be nil if config_scope == :project
            options   = eaf_value_config_key_options(project, config_scope, dir_level)
            keys      = user_config_options(ref: "'#{config_scope}'", options: options, ind: ind)
            no_?("Add a global config option for scope ('#{config_scope}')?", ind) ? keys : keys.unshift('global')
          end
        end

        def eaf_value_config_key_options(project, config_scope, dir_level)
          fetch_base_config(:projects_dirs).map do |dir|
            projects = project.to_sym == :global ? fetch_project_options_from_parent_dir(dir) : [project.to_s]
            next projects if config_scope.to_sym == :project # save nil config_scope from :project config_scope

            projects.map { |p| fetch_eaf_value_config_key_options_from_path(File.join(dir, p), dir_level) }.compact
          end.flatten.uniq.sort
        end

        def fetch_eaf_value_config_key_options_from_path(path, dir_level)
          return nil unless Dir.exist?(path)

          entries = Dir.glob(File.join(path, *Array.new(dir_level + 1, '*'))).select { |e| File.directory?(e) }
          entries.map { |e| File.basename(e) }
        end

        def setup_eaf_ref(schema:, ind: 5, **)
          info_(schema.fetch(:info), ind)
          prompt = 'Please enter file / 1Password path containing (or String of) the variable value'
          user_config_options(ref: 'value config reference', prompt_override: prompt, single: true, ind: ind)
        end

        def setup_eaf_format(schema:, ind: 5, **)
          info_(schema.fetch(:info), ind)
          args = { options: VALUE_CONFIG_FORMATS, with_custom: false, single: true }
          user_config_options(ref: 'value config format', **args, leading_br: false, ind: ind)
        end

        def setup_eaf_key(schema:, ref:, format:, ind: 5, **)
          return nil if skip_config_lookup?(format, schema.fetch(:nice_name), ind: ind)

          info_(schema.fetch(:info), ind)
          opts = fetch_eaf_config_key_options(ref, format)
          user_config_options(ref: 'value config key', options: opts, single: true, leading_br: false, ind: ind)
        rescue SetupError, JSON::ParserError => e
          warn_("Failed to parse environment variable value config: #{e.message}", ind)
          []
        end

        def fetch_eaf_config_key_options(config_ref, config_format)
          raw  = read_config_ref(config_ref)
          data = config_format == 'JSON' ? JSON.parse(raw) : YAML.safe_load(raw)
          raise SetupError, 'Parsed configuration is not a valid Hash (associative Array)' unless data.is_a?(Hash)

          data.keys
        end

        def read_config_ref(ref)
          if op_path?(ref)
            raise SetupError, '1Password CLI is not installed!' unless op_installed?

            fetch_op_secret(ref)
          else
            sops_installed? && sops_encrypted?(ref) ? read_sops(ref) : File.read(ref)
          end
        end

        def setup_eaf_config_subdivisions(schema:, key:, project:, ind: 5, **config)
          return nil if skip_config_lookup?(config.fetch(:format), schema.fetch(:nice_name), ind: ind)

          info_([schema.fetch(:info), eaf_config_subdivisions_example(key)].flatten, ind)
          if key
            prompt = "Is the environment variable value in a nested key under #{key}?"
            return nil unless yes_?(prompt, ind)
          end

          options = fetch_base_project_setting(project, :directory_structure).unshift('project')
          args    = { options: options, with_custom: false, with_escape: false }
          user_config_options(ref: 'config subdivision', **args, dir_tree: true, ind: ind)
        end

        def eaf_config_subdivisions_example(key)
          eg = [
            "  e.g. #{"{#{key}: " if key}{\"production\": {\"my_module\": \"{VALUE}\"} #{key ? '} }' : '}'} can be parsed with subdivisions",
            '        similar to ["environment", "module"] (as configured in the directory structure in terra_utils.json)'
          ]
          eg.push("If your config has no subdivisions and is just access via the #{key} key, please skip this section.") if key
        end

        def skip_config_lookup?(config_format, attr_name, ind: 5)
          return false if %w[JSON YAML].include?(config_format)

          warn_("#{attr_name} not required with selected source format (#{config_format})!", ind)
          true
        end
      end
    end
  end
end
