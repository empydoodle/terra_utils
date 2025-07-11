#!/usr/bin/env
# frozen_string_literal: true

require_relative '../terra_utils'

module TerraUtils
  # Secret retrieval helpers
  module SecretsHelpers
    ONEPASS = 'op'
    SOPS    = 'sops'

    # 1Password

    def onepass_path?(path)
      path.start_with?("#{ONEPASS}://")
    end

    def onepass_enabled?
      return @onepass_enabled unless @onepass_enabled.nil?

      enable_onepass_if_installed
    end

    def enable_onepass_if_installed
      return @onepass_enabled = false unless check_system_dependency(ONEPASS)

      require_relative '../one_pass_hax'
      extend OnePassHax
      @onepass_enabled = true
    end

    # SOPS

    def sops_enabled?
      return @sops_enabled unless @sops_enabled.nil?

      enable_sops_if_installed
    end

    def enable_sops_if_installed
      return @sops_enabled = false unless check_system_dependency(SOPS)

      require_relative '../sops_hax'
      extend SopsHax
      @sops_enabled = true
    end
  end
end
