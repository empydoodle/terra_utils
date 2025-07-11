#!/usr/bin/env ruby
# frozen_string_literal: true

module TerraUtils
  module Setup
    module ConfigFeaturesHelpers
      # Helpers for Terraform / Terragrunt version enforcement setup
      module TerraVersions
        CONFIG_TEMPLATE = File.join(T_U_CONFIG_TEMPLATES_DIR, 'terra_versions.json')

        def setup_terra_versions_config(project, ind: 3)
          %w[Terraform OpenTofu Terragrunt].map do |e|
            prompt_for_terra_pkg_version(project, e, ind: ind)
          end.compact.to_h
        end

        def prompt_for_terra_pkg_version(project, name, ind: 3)
          ref      = name.downcase.to_sym
          default  = parse_json_file(CONFIG_TEMPLATE).fetch(ref, {})[:version]
          if user_switch_prompt(prompt_override: "Does your project (#{project}) use #{name}?", leading_br: true, ind: ind)
            args = { prompt_override: "Please enter #{name} version to use", default: default, with_escape: true }
            [ref, user_option_prompt(**args, ind: ind)]
          elsif project.to_sym == :global
            [ref, nil]
          end
        end
      end
    end
  end
end
