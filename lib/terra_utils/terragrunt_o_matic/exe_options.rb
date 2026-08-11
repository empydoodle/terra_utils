#!/usr/bin/env ruby
# frozen_string_literal: true

require 'optparse'
require_relative '../terragrunt_o_matic'
require_relative '../exe_options'

module TerraUtils
  module TerragruntOMatic
    ## Provide options for TerraUtils::TerragruntOMatic executable (tg.rb)
    class ExeOptions < TerraUtils::ExeOptions
      include TerragruntOMatic

      EXE_NAME   = 'tg'
      EXE_TARGET = 'Terragrunt'

      DEFAULT_OPTIONS = TerraUtils::ExeOptions::DEFAULT_OPTIONS.dup.merge(
        {
          use_local_module: false,
          rm_cache: false,
          log_format: nil
        }
      ).freeze

      def iac_framework
        @terra_cmd = 'terragrunt'
      end

      def add_projects_dir
        super
        @examples << {
          desc: 'Use temporary projects parent directory for local Terraform / OpenTofu module in plan',
          usage: ['-l --projects-dir=/path/to/projects plan', '-l -P/path/to/projects p']
        }
      end

      def use_local_module?
        @optparse.on(
          '-l', '--use-local-module',
          'Use local Terraform / OpenTofu module (assumes {config["projects_dir"]} parent dir).'
        ) do
          @options[:use_local_module] = true
        end
        @examples << {
          desc: 'Plan against local version of Terraform / OpenTofu module',
          usage: ['-l plan']
        }
      end

      def delete_terragrunt_cache?
        @optparse.on(
          '-r', '--delete-terragrunt-cache',
          'Delete .terragrunt-cache before running Terragrunt.'
        ) do
          @options[:rm_cache] = true
        end
        @examples << {
          desc: 'Delete local cache before planning',
          usage: ['-r plan']
        }
      end

      def upgrade_provider_versions?
        super
        @examples << {
          desc: 'Upgrade providers using local module values',
          usage: ['-ul']
        }
      end

      def log_format
        @optparse.on(
          '-L', '--log-format[=LOG_FORMAT]',
          'Provide custom log format (or pass with no arg to use "%msg")'
        ) do |lf|
          @options[:log_format] = lf || '%msg'
        end
        @examples << {
          desc: 'Show only basic log from Terragrunt plan',
          usage: ['-L plan']
        }
        @examples << {
          desc: 'Show runtime and dir with Terragrunt plan log',
          usage: ['--log-format="%interval %prefix %msg"']
        }
      end

      def define_options
        use_local_module?
        delete_terragrunt_cache?
        log_format
        super
      end

      def default_examples
        [
          super,
          {
            desc: "Run command with arguments to the #{EXE_TARGET} command (enclose in quotes)",
            usage: ['"apply -target google_redis_instance.default"']
          }
        ].flatten
      end
    end
  end
end
