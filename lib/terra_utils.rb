#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'
require_relative 'danger_zone'
require_relative 'terra_utils/config_helpers'
require_relative 'terra_utils/secrets_helpers'
require_relative 'terra_utils/terra_helpers'

# Top level module
module TerraUtils
  REPO_ROOT           = File.expand_path(File.dirname(__FILE__, 2))
  VERSION             = File.read(File.join(REPO_ROOT, 'VERSION')).strip
  BIN_DIR             = File.join(REPO_ROOT, 'bin')
  CONFIG_DIR          = File.join(REPO_ROOT, 'config')

  DEFAULT_CONFIG_DIR  = File.join(Dir.home, '.config', 'terra_utils')
  DEFAULT_CONFIG_FILE = File.join(DEFAULT_CONFIG_DIR, 'terra_utils.json')

  # Custom error class for config discrepancies
  class ConfigError < StandardError; end

  def display_versions
    $stdout.puts('VERSIONS:')
    $stdout.puts("terra_utils: #{VERSION}")
    system('terraform  --version 2> /dev/null')
    system('opentofu   --version 2> /dev/null')
    system('terragrunt --version 2> /dev/null')
  end

  def check_system_dependency(cmd)
    system("which #{cmd} 1> /dev/null")
  end

  def parse_json_file(file_path, symbols: true)
    JSON.parse(File.read(file_path), symbolize_names: symbols)
  rescue JSON::ParserError => e
    raise ConfigError, "Failed to parse JSON file: #{file_path}. Error: #{e.message}"
  end
  module_function :parse_json_file

  def load_helpers
    extend DangerZone
    extend ConfigHelpers
    extend SecretsHelpers
    extend TerraHelpers
  end

  def enable_feature_command_aliases
    require_relative 'terra_utils/terra_alias'
    extend TerraAlias
    parse_alias_config
    true
  end

  def enable_feature_version_enforcement
    require_relative 'terra_utils/terra_versions'
    extend TerraUtils::TerraVersions
    parse_versions_config
    true
  end

  def enable_feature_state_backend_auto_auth
    require_relative 'terra_utils/backend_auto_auth'
    extend BackendAutoAuth
    parse_backend_auto_auth_config
    true
  end

  def enable_feature_environment_variable_auto_fill
    require_relative 'terra_utils/env_auto_fill'
    extend EnvAutoFill
    parse_env_auto_fill_config
    true
  end

  def feature_enabled?(lib)
    singleton_class.include?(self.class.const_get(lib))
  rescue NameError
    # uninitialized constant means library is not loaded
    false
  end
end
