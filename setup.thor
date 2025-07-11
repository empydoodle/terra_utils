#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'lib/terra_utils/setup'

# Setup script for terra_utils
class Setup < Thor
  include ::TerraUtils::Setup

  INTRO_STYLE   = [:tall].freeze
  INTRO_OPTIONS = { margin: 13 }.freeze

  package_name 'TerraUtils'
  default_command :all

  def self.source_paths
    [T_U_EXECUTABLES_DIR, T_U_CONFIG_DIR, T_U_CONFIG_TEMPLATES_DIR]
  end

  desc 'all', 'Setup terra_utils for use on your workstation.'
  method_option :config_dir, type: :string, desc: "Alternative directory for config (default: #{USER_T_U_CONFIG_DIR})"
  method_option :exe_dir,    type: :string, desc: "Alternative directory for executable (default: #{USER_EXECUTABLES_DIR})"
  def all
    intro_main
    abort unless yes_?('Proceed with setup?', :parag)

    @config_dir  = options.fetch(:config_dir, USER_T_U_CONFIG_DIR)
    @exe_dir     = options.fetch(:exe_dir, USER_EXECUTABLES_DIR)

    setup_config(@config_dir)
    say_('Setting up executables - sudo access is required', :yellow, :leading_br)
    system("(cd #{__dir__} ; sudo thor setup:executables #{@exe_dir})")
    say('Setup complete!', :green)
    config_files.each { |k, v| say("Please ensure API key for #{k} is populated correctly [#{v}]", :yellow) }
  end

  desc 'config', "Set up config files in specified directory (default: #{USER_T_U_CONFIG_DIR}) [used by :all]"
  def setup_config(config_dir = nil, indent = nil)
    @config_dir ||= config_dir || USER_T_U_CONFIG_DIR
    indent        = indent.to_i # nil => 0
    intro_config(indent)
    base_config(@config_dir, indent + 1)
    feature_config(@config_dir, indent + 1)
  end

  desc 'base_config', "Set up base terra_utils.json config file in specified directory (default: #{USER_T_U_CONFIG_DIR}) [used by :setup_config]"
  def base_config(config_dir = nil, indent = nil)
    @config_dir ||= config_dir || USER_T_U_CONFIG_DIR
    indent        = indent.to_i # nil => 0
    intro_base_config(indent)
    setup_base_config_file(ind: indent)
  end

  desc 'feature_config', "Set up feature-specific config file(s) in specified directory (default: #{USER_T_U_CONFIG_DIR}) [used by :setup_config]"
  def feature_config(config_dir = nil, indent = nil)
    @config_dir  ||= config_dir || USER_T_U_CONFIG_DIR
    indent         = indent.to_i # nil => 0
    intro_feature_config(indent)
    setup_feature_config_files(ind: indent)
  end

  desc 'executables', 'Create symlinks for the executable files [used by :all]'
  def executables(exe_dir = nil, indent = nil)
    @exe_dir ||= exe_dir || EXECUTABLES_DIR
    indent     = indent.to_i # nil => 0
    intro_executables(indent)
    EXECUTABLES.each { |exe| setup_exe_symlink(dir: exe_dir, ind: indent + 1, **exe) }
  end

  private

  def intro_main
    intro('TERRA UTILS', margin: 42)
    say_('Please ensure you have installed dependent system packages! (Brewfile / install_dependencies.sh)', :yellow)
    say_('Please ensure you have installed dependent Ruby gems via bundler!', :yellow)
  end

  def intro_config(indent = nil)
    intro('CONFIGURATION SETUP', indent)
    say_("Setting up config files in #{@config_dir}...", indent)
  end

  def intro_base_config(indent = nil)
    intro(['BASE CONFIGURATION', 'This will set up the main configuration for TerraUtils.'], indent)
  end

  def intro_feature_config(indent = nil)
    header_txt = [
      'FEATURE CONFIGURATION',
      'This will set up the configurations for TerraUtils features enabled in the base configuration.'
    ]
    intro(header_txt, indent)
    say_("Checking feature config files in #{@config_dir}...", indent)
  end

  def intro_executables(indent = nil)
    intro('EXECUTABLES SETUP', indent)
    say_("Creating symlinks to executables in #{@exe_dir}...", indent)
  end

  def intro(text, *style, **options)
    header_(text, *style, *INTRO_STYLE, **INTRO_OPTIONS, **options)
  end

  def verify_base_config(config_dir)
    paths = [config_dir, TerraUtils::Setup::USER_T_U_CONFIG_DIR].map do |dir|
      path = File.join(dir, 'terra_utils.json')
      return path if File.exist?(path)

      path
    end
    raise "Unable to locate base config file from expected paths: #{paths}"
  end

  def update_features_config_paths
    T_U_FEATURES.dup.map do |feat|
      file = feat.dig(:config, :config_file)
      feat[:config][:config_file] = File.join(@config_dir, file) if file
    end
  end
end
