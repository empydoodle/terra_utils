#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../terragrunt_o_matic'
require_relative '../base'

module TerraUtils
  module TerragruntOMatic
    ## Instance of TerragruntOMatic based on pwd
    class Base < TerraUtils::Base
      include TerragruntOMatic

      attr_accessor :rm_cache, :use_local_module, :log_format

      def initialize(options, argv_array)
        super(options, argv_array)
        @terra_cmd = 'terragrunt'
      end

      def generate_cmd
        [
          # module cache
          'TG_PROVIDER_CACHE=1',
          'TG_PROVIDER_CACHE_DIR=$HOME/.terraform.d/plgun-cache',
          # debugging
          ('TG_LOG_LEVEL=debug' if @debug),
          super,
          (tg_source_switch if @use_local_module),
          (tg_log_format(@log_format) if @log_format)
        ].flatten.compact
      end

      def run
        pre_run
        return false unless @exe_cmd

        authenticate_state_backend
        delete_tg_cache if @rm_cache
        system(@cmd)
        true
      end
    end
  end
end
