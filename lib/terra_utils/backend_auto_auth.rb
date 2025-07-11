#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../terra_utils'

module TerraUtils
  # Module for auto-authentication with backend services
  module BackendAutoAuth
    FEATURE_IDENT = :state_backend_auto_auth

    def auto_auth_project_config
      project_features_config.fetch(FEATURE_IDENT)
    end

    def parse_backend_auto_auth_config
      log_debug("Parsing feature config (#{FEATURE_IDENT})")
      @backend_auto_auth_cmd ||= auto_auth_project_config.fetch(:command)
    end

    def auth_state_backend
      # Use configured command to authenticate with terraform state backend provider
      raise ConfigError, 'No state_backend_auto_auth command configured' unless @backend_auto_auth_cmd

      log('Authenticating with state backend provider...')
      log_debug("  Command: #{@backend_auto_auth_cmd}") if @debug
      system(@backend_auto_auth_cmd)
      log('... authentication complete!')
    end
  end
end
