#!/usr/bin/env ruby
# frozen_string_literal: true

require 'optparse'
require_relative '../terragrunt_o_matic'

module TerraUtils
  module TerragruntOMatic
    ## Provide options for TerraUtils::TerragruntOMatic executable (tg.rb)
    class ExeOptions
      include TerragruntOMatic

      DEFAULT_OPTIONS = {
        use_local_tf: false,
        rm_cache: false,
        upgrade_providers: false,
        exe_cmd: true,
        enforce_versions: true,
        state_backend_auto_auth: nil,
        backend_auto_auth_cmd: nil,
        config_path: nil,
        environment_variable_autofill: nil,
        env_autofill_config_path: nil,
        addit_projects_dir: nil,
        debug: false
      }.freeze

      DEFAULT_EXAMPLES = [
        {
          desc: 'Run Terragrunt command (e.g. apply)',
          usage: ['tg apply']
        },
        {
          desc: 'Run Terragrunt command via alias (e.g. plan)',
          usage: ['tg p']
        },
        {
          desc: 'Run command with arguments to the Terragrunt command (enclose in quotes)',
          usage: ['tg "apply -target google_redis_instance.default"']
        }
      ].freeze

      attr_accessor :options

      def initialize(options = nil)
        @optparse = OptionParser.new
        @examples = DEFAULT_EXAMPLES.dup
        @options  = options || DEFAULT_OPTIONS.dup
      end

      def set_alternative_config
        @optparse.on(
          '-c', '--config=CONFIG_FILE_PATH',
          "Use alternative terra_utils config file (default: #{DEFAULT_CONFIG_FILE})."
        ) do |path|
          @options[:config_path] = path.strip
        end
        @examples << {
          desc: 'Run tg using an alternative config',
          usage: ['tg --config=/path/to/config.json plan', 'tg -c/path/to/config.json p']
        }
      end

      def use_local_terraform_module?
        @optparse.on(
          '-l', '--use-local-terraform',
          'Use local Terraform module (assumes {config["projects_dir"]} parent dir).'
        ) do
          @options[:use_local_tf] = true
        end
        @examples << {
          desc: 'Plan against local version of Terraform module',
          usage: ['tg -l plan']
        }
      end

      def print_terragrunt_command_only?
        @optparse.on(
          '-p', '--print-command-only',
          'Print full command for verification (DOES NOT RUN TERRAGRUNT).'
        ) do
          @options[:exe_cmd] = false
        end
        @examples << {
          desc: 'Check generated command without running Terragrunt',
          usage: ['tg -p apply']
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
          usage: ['tg -r plan']
        }
      end

      def upgrade_provider_versions?
        @optparse.on(
          '-u', '--upgrade-providers',
          'Upgrade providers & lock file ONLY (will disregard other actions).'
        ) do
          @options[:upgrade_providers] = true
        end
        @examples << {
          desc: 'Upgrade Terraform providers and update .terraform.lock.hcl with all configured platforms',
          usage: ['tg -u']
        }
        @examples << {
          desc: 'Upgrade providers using local Terraform module values',
          usage: ['tg -ul']
        }
      end

      def state_backend_auth_parameters
        @optparse.on(
          '-A', '--[no-]state-auth[-command="COMMAND"]',
          'Use different Terraform state backend auto-authentication settings (see usage examples).'
        ) do |cmd|
          if cmd.is_a?(String)
            @options[:state_backend_auto_auth] = true
            @options[:backend_auto_auth_cmd] = cmd.strip
          else
            @options[:state_backend_auto_auth] = false
          end
        end
        @examples << {
          desc: 'Apply changes without first authenticating with state backend provider (if enabled in config)',
          usage: ['tg --no-state-auth apply', 'tg -A a']
        }
        @examples << {
          desc: 'Plan using a different command to authenticate with state backend provider than the one configured',
          usage: ['tg --state-auth-command="saml2aws login" plan', 'tg -A"saml2aws login" p']
        }
      end

      def env_auto_fill_parameters
        @optparse.on(
          '-E', '--[no-]env-autofill[-config=CONFIG_FILE_PATH]',
          'Use different environment variable autofill settings (see usage examples).'
        ) do |path|
          if path.is_a?(String)
            @options[:environment_variable_autofill] = true
            @options[:env_autofill_config_path] = path.strip
          else
            @options[:environment_variable_autofill] = false
          end
        end
        @examples << {
          desc: 'Plan without autofilling environment variables (if enabled in config)',
          usage: ['tg --no-env-autofill p', 'tg -E p']
        }
        @examples << {
          desc: 'Use alternative config for environment variable autofilling during apply',
          usage: ['tg --env-autofill-config=/path/to/env_auto_fill.json apply', 'tg -E/path/to/config.json a']
        }
      end

      def add_projects_dir
        @optparse.on(
          '-P', '--projects-dir=PROJECTS_DIR_PATH',
          'Use projects dir not in TerraUtils config.'
        ) do |path|
          path = path.strip
          Dir.exist?(path) ? options[:addit_projects_dir] = path : (raise ArgumentError, "#{path} does not exist!")
        end
        @examples << {
          desc: 'Use temporary projects directory for local Terraform module in plan',
          usage: ['tg -l --projects-dir=/path/to/projects plan', 'tg -l -P/path/to/projects p']
        }
      end

      def enforce_terra_versions?
        @optparse.on(
          '-V', '--disable-version-enforcement',
          'Disable enforcement of Terraform/Terragrunt version in project configuration.'
        ) do
          @options[:enforce_versions] = false
        end
        @examples << {
          desc: 'Run plan without enforcing Terraform/Terragrunt version (using default / system versions)',
          usage: ['tg -V plan']
        }
      end

      def enable_debug
        @optparse.on(
          '-d', '--debug',
          'Enable debug output for TerraUtils, Terraform and Terragrunt.'
        ) do
          @options[:debug] = true
        end
        @examples << {
          desc: 'Plan with debug output',
          usage: ['tg -d plan']
        }
      end

      def versions_output
        @optparse.on('-v', '--version', 'Show version.') do
          display_versions
          exit
        end
      end

      def define_options
        set_alternative_config
        use_local_terraform_module?
        print_terragrunt_command_only?
        delete_terragrunt_cache?
        upgrade_provider_versions?
        state_backend_auth_parameters
        env_auto_fill_parameters
        add_projects_dir
        enforce_terra_versions?
        enable_debug
        versions_output
      end

      def generate_usage_examples
        desc_indent    = '  - '
        usage_indent   = '      '
        @examples.map do |example|
          [
            [desc_indent, example[:desc]].join,
            example[:usage].map { |ue| [usage_indent, ue].join },
            ''
          ]
        end.flatten.insert(0, 'USAGE EXAMPLES').join("\n")
      end

      def help_output
        @optparse.on('-h', '--help', 'Show this help message.') do
          $stdout.puts(@optparse)
          $stdout.puts('')
          $stdout.puts(generate_usage_examples)
          $stdout.puts('')
          display_versions
          exit
        end
      end

      def set_banner
        @optparse.banner = <<~BANNER
          tg - Executable for the TerraUtils utility using Terragrunt

          CONFIGURATION
            Features can be enabled or disabled in config (default file:~/.config/terra_utils.json)
            - Terraform / Terragrunt command aliases
            - Automatic Terraform state backend provider authentication
            - Autofilling environment variables for provider config (e.g. monitoring / alerting providers)

          USAGE
            tg [options] "[terragrunt command]"

        BANNER
      end

      def parse_options!
        @optparse.program_name = 'tg'
        set_banner
        @optparse.separator 'OPTIONS:'
        define_options
        help_output
        @optparse.parse!
      end
    end
  end
end
