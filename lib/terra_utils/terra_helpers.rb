# /usr/bin/env ruby
# frozen_string_literal: true

require_relative '../terra_utils'

module TerraUtils
  # General Terraform helper methoda
  module TerraHelpers
    def switch_tf_version
      version = @project_config.fetch(:terraform_version)
      return unless version

      system("tfswitch #{version}")
    rescue KeyError
      # If not configured, use system terraform
    end

    def generate_init_upgrade_cmd(**_)
      'init -upgrade'
    end

    def generate_providers_lock_cmd
      [
        'providers lock',
        fetch_config(:terraform_provider_platforms).map { |p| "-platform=#{p}" }
      ].flatten.join(' ')
    end

    def upgrade_providers_and_lock
      [
        @terra_cmd,
        generate_init_upgrade_cmd,
        '&&',
        @terra_cmd,
        generate_providers_lock_cmd
      ]
    end
  end
end
