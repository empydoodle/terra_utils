# /usr/bin/env ruby
# frozen_string_literal: true

require 'json'
require_relative '../terra_utils'

module TerraUtils
  # Version enforcement for Terraform tools via `tenv`
  module TerraVersions
    FEATURE_IDENT = :version_enforcement
    SWITCHERS     = {
      terraform: 'tfswitch',
      opentofu: 'TF_PRODUCT="opentofu" tfswitch',
      terragrunt: 'tgswitch'
    }.freeze

    def versions_project_config
      project_features_config.fetch(FEATURE_IDENT)
    rescue KeyError => e
      raise ConfigError, "Unable to fetch Version Enforcement feature config from project config! Error: #{e.message}"
    end

    def versions_config_file
      versions_project_config.fetch(:config_file)
    end

    def parse_versions_config
      # Specifically don't convert to symbols here
      log_debug("Parsing feature config (#{FEATURE_IDENT}): #{versions_config_file}")
      @versions_config = parse_json_file(versions_config_file)
    rescue JSON::ParserError => e
      raise ConfigError, "Failed to parse versions config: #{version_config_file}. Error: #{e.message}"
    end

    def enforce_terra_version(util)
      version = @versions_config.fetch(util).fetch(:version, nil)
      return false if version.nil? || version.empty?

      switcher = SWITCHERS.fetch(util)
      log("Enforcing #{util} version: #{version}")
      silent_cmd("#{switcher} #{version}")
      log("Switched #{util} version to #{version}")
    end

    def enforce_terra_versions
      utils ||= @versions_config.keys
      [utils].flatten.each do |util|
        enforce_terra_version(util)
      rescue KeyError, SystemCallError => e
        # If not configured / installed, use system util
        log_err("Unable to enforce #{util} version: #{e.message}")
        log("Using system #{util}...")
      end
    end
  end
end
