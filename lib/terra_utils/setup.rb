#!/usr/bin/env ruby
# frozen_string_literal: true

require 'thor'
require 'date'
require 'json'
require_relative 'setup/setup_helpers'
require_relative 'setup/config_file_helpers'
require_relative 'setup/config_helpers'
require_relative 'setup/config_base_helpers'
require_relative 'setup/config_base_feature_helpers'
require_relative 'setup/config_feature_helpers'
require_relative 'setup/exe_file_helpers'

module TerraUtils
  ## Setup module for TerraUtils
  module Setup
    SUBMODULES = [
      Thor::Base,
      Thor::Shell,
      Thor::Actions,
      SetupHelpers,
      ConfigFileHelpers,
      ConfigHelpers,
      ConfigBaseHelpers,
      ConfigBaseFeatureHelpers,
      ConfigFeatureHelpers,
      ExeFileHelpers
    ].freeze

    def parse_json_file(file_path, symbols: true)
      JSON.parse(File.read(file_path), symbolize_names: symbols)
    end
    module_function :parse_json_file

    T_U_ROOT                 = File.expand_path(File.dirname(__dir__, 2))
    T_U_BIN_DIR              = File.join(T_U_ROOT, 'bin')
    T_U_CONFIG_DIR           = File.join(T_U_ROOT, 'config')
    T_U_CONFIG_TEMPLATES_DIR = File.join(T_U_CONFIG_DIR, 'templates')
    T_U_FEATURES_CONFIG_FILE = File.join(T_U_CONFIG_DIR, 'features.json')
    T_U_FEATURES             = parse_json_file(T_U_FEATURES_CONFIG_FILE)
    USER_CONFIG_DIR          = File.join(Dir.home, '.config')
    USER_T_U_CONFIG_DIR      = File.join(USER_CONFIG_DIR, 'terra_utils')
    USER_T_U_CONFIG          = File.join(USER_T_U_CONFIG_DIR, 'terra_utils.json')
    EXECUTABLES_DIR          = File.join('', 'usr', 'local', 'bin')
    EXECUTABLES              = [{ src_exe: 'tg.rb', default_exe_name: 'tg' }].freeze

    def self.included(base)
      SUBMODULES.each { |m| base.include(m) }
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
  end
end
