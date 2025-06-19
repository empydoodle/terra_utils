#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../terragrunt_o_matic'
require_relative '../base'

module TerraUtils
  module TerragruntOMatic
    ## Instance of TerragruntOMatic based on pwd
    class Base < TerraUtils::Base
      include TerragruntOMatic

      attr_accessor :rm_cache, :use_local_tf

      def initialize(options, argv_array)
        super(options, argv_array)
        switch_tg_version if @enforce_versions
        @terra_cmd = 'terragrunt'
      end

      def generate_cmd
        [
          ('TG_LOG_LEVEL=debug' if @debug),
          super,
          (tg_source_switch if @use_local_tf)
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
