#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'
require_relative 'danger_zone'
require_relative 'terra_utils/config_helpers'
require_relative 'terra_utils/terra_helpers'

# Top level module
module TerraUtils
  REPO_ROOT           = File.expand_path(File.dirname(__FILE__, 2))
  VERSION             = File.read(File.join(REPO_ROOT, 'VERSION')).strip
  DEFAULT_CONFIG_DIR  = File.join(Dir.home, '.config', 'terra_utils')
  DEFAULT_CONFIG_FILE = File.join(DEFAULT_CONFIG_DIR, 'terra_utils.json')

  # Custom error class for config discrepancies
  class ConfigError < StandardError
  end

  def display_versions
    $stdout.puts('VERSIONS:')
    $stdout.puts("terra_utils: #{VERSION}")
    system('terragrunt --version')
    system('terraform --version')
  end

  def parse_json_file(file_path, symbols: true)
    JSON.parse(File.read(file_path), symbolize_names: symbols)
  rescue JSON::ParserError => e
    raise ConfigError, "Failed to parse JSON file: #{file_path}. Error: #{e.message}"
  end

  def load_helpers
    extend DangerZone
    extend ConfigHelpers
    extend TerraHelpers
  end

  def enable_aliases
    require_relative 'terra_utils/terra_alias'
    extend TerraAlias
    parse_alias_config
    true
  end

  def enable_backend_auto_auth
    require_relative 'terra_utils/backend_auto_auth'
    extend BackendAutoAuth
    parse_backend_auto_auth_config
    true
  end

  def enable_env_auto_fill
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
