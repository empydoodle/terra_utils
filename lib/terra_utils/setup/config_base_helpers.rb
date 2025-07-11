#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'config_base_helpers/base'
require_relative 'config_base_helpers/projects'
require_relative 'config_base_helpers/features'

module TerraUtils
  module Setup
    # Collect helpers to populate main config
    module ConfigBaseHelpers
      SUBMODULES = [
        Base,
        Projects,
        Features
      ].freeze

      def self.included(base)
        SUBMODULES.each { |m| base.include(m) }
      end

      def setup_base_config_file(ind: 1)
        file = 'terra_utils.json'
        schema = {
          name: 'terra_utils',
          nice_name: 'Terra Utils',
          config: {
            config_file: File.join(@config_dir, file),
            config_template: file
          }
        }
        setup_config_file(schema, ind: ind)
      end
    end
  end
end
