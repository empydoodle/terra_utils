#!/usr/bin/env ruby
# frozen_string_literal: true

require 'thor'
require 'date'
require 'json'
require_relative '../thor_helpers'
require_relative 'setup/setup_helpers'
require_relative 'setup/config_file_helpers'
require_relative 'setup/config_base_helpers'
require_relative 'setup/config_features_helpers'
require_relative 'setup/exe_file_helpers'

module TerraUtils
  ## Setup module for TerraUtils
  module Setup
    # Custom error class for config discrepancies
    class SetupError < StandardError; end

    T_U_ROOT = File.expand_path(File.dirname(__dir__, 2))

    T_U_CONFIG_DIR           = File.join(T_U_ROOT, 'config')
    T_U_CONFIG_TEMPLATES_DIR = File.join(T_U_CONFIG_DIR, 'templates')
    T_U_CONFIG_SCHEMA_DIR    = File.join(T_U_CONFIG_DIR, 'schema')

    T_U_EXECUTABLES_DIR = File.join(T_U_ROOT, 'bin')
    T_U_EXECUTABLES     = %w[tu tg].map { |exe| [exe, { default_exe_name: exe, src_exe: "#{exe}.rb" }] }.freeze

    USER_CONFIG_DIR      = File.join(Dir.home, '.config')
    USER_T_U_CONFIG_DIR  = File.join(USER_CONFIG_DIR, 'terra_utils')
    USER_T_U_CONFIG      = File.join(USER_T_U_CONFIG_DIR, 'terra_utils.json')
    USER_EXECUTABLES_DIR = File.join('', 'usr', 'local', 'bin')

    SUBMODULES = [
      Thor::Base,
      Thor::Shell,
      Thor::Actions,
      ::ThorHelpers,
      SetupHelpers,
      ConfigFileHelpers,
      ConfigBaseHelpers,
      ConfigFeaturesHelpers,
      ExeFileHelpers
    ].freeze

    def parse_json_file(file_path, symbols: true)
      JSON.parse(File.read(file_path), symbolize_names: symbols)
    end

    def check_system_dependency(cmd)
      system("which #{cmd} 1> /dev/null")
    end

    def op_path?(path)
      path.start_with?('op://')
    end

    def op_installed?
      return @onepass unless @onepass.nil?

      @onepass = check_system_dependency('op')
      return false unless @onepass

      require File.join(T_U_ROOT, 'lib', 'one_pass_hax')
      extend OnePassHax
      true
    end

    def sops_installed?
      return @sops unless @sops.nil?

      @sops = system('which sops 1> /dev/null') unless @sops.nil?
      return false unless @sops

      require File.join(T_U_ROOT, 'lib', 'sops_hax')
      extend SopsHax
      true
    end

    def fetch_base_config(*path, symbols: true)
      file   = File.join(@config_dir, 'terra_utils.json')
      config = parse_json_file(file, symbols: symbols)
      return config if path.empty?

      path.flatten.each { |e| config = config.fetch(e) }
      config
    end

    def fetch_base_project_config(project)
      fetch_base_config(:projects_settings, project.to_sym)
    end

    def fetch_base_project_setting(project, setting)
      fetch_base_config(:projects_settings, project.to_sym, setting.to_sym)
    rescue KeyError, NoMethodError
      # default to global config
      fetch_base_config(:projects_settings, :global, setting.to_sym)
    end

    def fetch_schema(*path)
      parse_json_file(File.join(T_U_CONFIG_SCHEMA_DIR, *path.flatten))
    end

    def setup_from_schema(schema, ind:, method: nil, **args)
      header_([schema.fetch(:nice_name).upcase, schema.fetch(:description)].compact, ind)
      method ||= "setup_#{schema.fetch(:name)}"
      public_send(method.to_sym, schema: schema, ind: ind, **args)
    end

    def self.included(base)
      SUBMODULES.each { |m| base.include(m) }
    end
  end
end
