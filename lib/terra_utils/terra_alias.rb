# /usr/bin/env ruby
# frozen_string_literal: true

require 'json'
require_relative '../terra_utils'

module TerraUtils
  # QOL aliases for Terragrunt commands
  module TerraAlias
    FEATURE_IDENT = :command_aliases

    def alias_project_config
      project_features_config.fetch(FEATURE_IDENT)
    rescue KeyError => e
      raise ConfigError, "Unable to fetch Command Aliases feature config from project config! Error: #{e.message}"
    end

    def alias_config_file
      alias_project_config.fetch(:config_file)
    end

    def parse_alias_config
      # Specifically don't convert to symbols here
      log_debug("Parsing feature config (#{FEATURE_IDENT}): #{alias_config_file}")
      @alias_config = parse_json_file(alias_config_file, symbols: false)
    rescue JSON::ParserError => e
      raise ConfigError, "Failed to parse alias config: #{alias_config_file}. Error: #{e.message}"
    end

    def validate_config(cmd_alias)
      @alias_config ||= parse_alias_config
      hits = @alias_config.select { |_k, v| v == cmd_alias }
      raise ConfigError, "Multiple aliases configured for `#{cmd_alias}` (#{hits.keys})" if hits.size > 1
    end

    def interpret_alias(cmd_alias)
      validate_config(cmd_alias)
      @alias_config.key(cmd_alias) || cmd_alias
    end
  end
end
