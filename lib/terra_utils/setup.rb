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
require_relative 'setup/exe_file_helpers'

module TerraUtils
  ## Setup module for TerraUtils
  module Setup
    T_U_ROOT                 = File.expand_path(File.dirname(__dir__, 2))
    T_U_BIN_DIR              = File.join(T_U_ROOT, 'bin')
    T_U_CONFIG_DIR           = File.join(T_U_ROOT, 'config')
    T_U_CONFIG_TEMPLATES_DIR = File.join(T_U_CONFIG_DIR, 'templates')
    T_U_MAIN_CONFIG_TEMPLATE = JSON.parse(File.read(File.join(T_U_CONFIG_TEMPLATES_DIR, 'terra_utils.json')))
    T_U_FEATURES_CONFIG_FILE = File.join(T_U_CONFIG_DIR, 'features.json')
    T_U_FEATURES             = JSON.parse(File.read(T_U_FEATURES_CONFIG_FILE), symbolize_names: true)
    USER_CONFIG_DIR          = File.join(Dir.home, '.config')
    USER_T_U_CONFIG_DIR      = File.join(USER_CONFIG_DIR, 'terra_utils')
    USER_T_U_CONFIG          = File.join(USER_T_U_CONFIG_DIR, 'terra_utils.json')
    EXECUTABLES_DIR          = File.join('', 'usr', 'local', 'bin')
    EXECUTABLES              = [{ src_exe: 'tg.rb', default_exe_name: 'tg' }].freeze

    SUBMODULES = [
      Thor::Base,
      Thor::Shell,
      Thor::Actions,
      SetupHelpers,
      ConfigFileHelpers,
      ConfigHelpers,
      ConfigBaseHelpers,
      ConfigBaseFeatureHelpers,
      ExeFileHelpers
    ].freeze

    def self.included(base)
      SUBMODULES.each { |m| base.include(m) }
    end
  end
end
