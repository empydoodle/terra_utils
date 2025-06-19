#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../terra_utils'
require_relative 'terragrunt_o_matic/grunt_helpers'

module TerraUtils
  ## Wrapper for Terragrunt automations / shortcuts
  module TerragruntOMatic
    extend TerraUtils

    def load_helpers
      super
      extend GruntHelpers
    end
  end
end
