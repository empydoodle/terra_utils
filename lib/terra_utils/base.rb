#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../terra_utils'

module TerraUtils
  ## Wrapper for Terragrunt automations / shortcuts
  class Base
    include TerraUtils

    attr_accessor :projects_dir, :project_config, :terra_cmd, :terra_subcmd,
                  :debug, :exe_cmd, :config, :upgrade_providers, :enforce_version,
                  :state_backend_auto_auth, :backend_auto_auth_cmd,
                  :environment_variable_autofill, :env_autofill_config_path
    attr_reader   :options, :args, :projects_dirs, :addit_projects_dir, :path, :project, :scope

    def initialize(options, argv_array)
      load_helpers
      @options = options
      set_config
      extract_scope
      validate_features
      switch_tf_version if @enforce_versions
      @args = argv_array.flat_map(&:split) # workaround passing args as single string, e.g. $ tg "plan -target x"
      @terra_subcmd = parse_subcmd_alias(@args.shift)
      @terra_cmd    = 'terraform'
    end

    def generate_cmd
      return upgrade_providers_and_lock if @upgrade_providers

      [
        ('TF_LOG=debug' if @debug),
        collate_env_vars,
        @terra_cmd,
        @terra_subcmd,
        @args
      ].flatten.compact
    end

    def pre_run
      @cmd = generate_cmd.join(' ')
      debug_output if @debug
      log(@scope)
      log('Command:')
      log("  #{@cmd}\n")
    end

    def run
      pre_run
      return false unless @exe_cmd

      authenticate_state_backend
      system(@cmd)
      true
    end

    private

    def set_options
      @options.each { |k, v| instance_variable_set("@#{k}".to_sym, v) }
    end

    def select_projects_dir
      projects_dir = @projects_dirs.reverse.find { |dir| Dir.pwd.start_with?(dir) }
      unless projects_dir
        err = "#{Dir.pwd} has no configured projects dir in config[:projects_dirs] (#{@projects_dirs}) - please add or use -P"
        raise ConfigError, err
      end
      projects_dir
    end

    def set_config
      set_options
      @config_path    ||= DEFAULT_CONFIG_FILE
      @config           = parse_config(@config_path)
      @projects_dirs    = fetch_config(:projects_dirs).push(@addit_projects_dir).compact
      @projects_dir   ||= select_projects_dir
      @path_arr         = Dir.pwd.sub(@projects_dir, '').split('/')[1..]
      @project          = @path_arr.shift
      @project_config   = parse_project_config
    end

    def extract_scope
      struct = @project_config.fetch(:directory_structure)
      @scope = (0..struct.size - 1).to_a.map do |i|
        [struct[i], @path_arr[i]]
      end.to_h
    end

    def skip_cmd?
      # Determine if tg can run without a passed command
      [
        @upgrade_providers == true
      ].include?(true)
    end

    def parse_subcmd_alias(raw_subcmd)
      return raw_subcmd unless feature_enabled?('TerraAlias') && !skip_cmd?

      interpret_alias(raw_subcmd)
    end

    def collate_env_vars
      return nil unless feature_enabled?('EnvAutoFill') && autofill_env?

      generate_env_vars
    end

    def authenticate_state_backend
      return false unless feature_enabled?('BackendAutoAuth')

      auth_state_backend
      true
    end

    def debug_output
      log_debug("Options:          #{@options.inspect}")
      log_debug("Terra Command:    #{@terra_cmd.inspect}")
      log_debug("Terra Subcommand: #{@terra_subcmd.inspect}")
      log_debug("Arguments:        #{@args.inspect}")
      log_debug("Enabled Features: #{list_enabled_features}")
    end
  end
end
