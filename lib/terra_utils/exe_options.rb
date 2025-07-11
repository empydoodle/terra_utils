#!/usr/bin/env ruby
# frozen_string_literal: true

require 'optparse'
require_relative '../terra_utils'

module TerraUtils
  ## Provide options for TerraUtils executable (tu.rb)
  class ExeOptions
    include TerraUtils

    EXE_NAME   = 'tu'
    EXE_TARGET = 'Terraform / OpenTofu'

    DEFAULT_OPTIONS_FILE = File.join(CONFIG_DIR, 'tu_defaults.json')
    DEFAULT_OPTIONS      = TerraUtils.parse_json_file(DEFAULT_OPTIONS_FILE)

    attr_accessor :options

    def initialize(options = nil)
      @optparse = OptionParser.new
      @examples = []
      @options  = options || self.class::DEFAULT_OPTIONS.dup
    end

    def set_alternative_config
      @optparse.on(
        '-c', '--config=CONFIG_FILE_PATH',
        "Use alternative terra_utils config file (default: #{DEFAULT_CONFIG_FILE})."
      ) do |path|
        @options[:config_path] = path.strip
      end
      @examples << {
        desc: "Run #{self.class::EXE_NAME} using an alternative config",
        usage: ['--config=/path/to/config.json plan', '-c/path/to/config.json p']
      }
    end

    def print_command_only?
      @optparse.on(
        '-p', '--print-command-only',
        'Print full command for verification (DOES NOT RUN COMMAND).'
      ) do
        @options[:exe_cmd] = false
      end
      @examples << {
        desc: 'Check generated command without running Terragrunt',
        usage: ['-p apply']
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
        desc: 'Upgrade providers and update lockfile (e.g. .terraform.lock.hcl) with all configured platforms',
        usage: ['-u']
      }
    end

    def state_backend_auth_parameters
      @optparse.on(
        '-A', '--[no-]state-auth[-command="COMMAND"]',
        'Use different state backend auto-authentication settings (see usage examples).'
      ) do |cmd|
        if cmd.is_a?(String)
          @options[:state_backend_auto_auth] = true
          @options[:backend_auto_auth_cmd]   = cmd.strip
        else
          @options[:state_backend_auto_auth] = false
        end
      end
      @examples << {
        desc: 'Apply changes without first authenticating with state backend provider (if enabled in config)',
        usage: ['--no-state-auth apply', '-A a']
      }
      @examples << {
        desc: 'Plan using a different command to authenticate with state backend provider than the one configured',
        usage: ['--state-auth-command="saml2aws login" plan', '-A"saml2aws login" p']
      }
    end

    def env_auto_fill_parameters
      @optparse.on(
        '-E', '--[no-]env-auto-fill[-config=CONFIG_FILE_PATH]',
        'Use different environment variable auto-fill settings (see usage examples).'
      ) do |path|
        if path.is_a?(String)
          @options[:environment_variable_auto_fill] = true
          @options[:env_auto_fill_config_path] = path.strip
        else
          @options[:environment_variable_auto_fill] = false
        end
      end
      @examples << {
        desc: 'Plan without auto-filling environment variables (if enabled in config)',
        usage: ['--no-env-auto-fill p', '-E p']
      }
      @examples << {
        desc: 'Use alternative config for environment variable auto-filling during apply',
        usage: ['--env-auto-fill-config=/path/to/env_auto_fill.json apply', '-E/path/to/config.json a']
      }
    end

    def iac_framework
      @optparse.on(
        '-F', '--iac-framework=FRAMEWORK',
        'Override configured Infrastructure-As-Code framework (default: terraform).'
      ) do |iac|
        if iac.strip =~ /^[tT][(erra)(ERRA]?[fF][(orm)(ORM)]?$/
          @terra_cmd = 'terraform'
        elsif iac.strip =~ /^[oO]?[(pen)(PEN)]?[tT][(ofu)(OFU)]?$/
          @terra_cmd = 'opentofu'
        end
      end
      @examples << {
        desc: 'Override configured IAC framework to Terraform and plan',
        usage: ['--iac-framework=terraform plan', '-E tf p']
      }
      @examples << {
        desc: 'Override configured IAC framework to OpenTofu and initialise',
        usage: ['--iac-framework=opentofu plan', '-E tofu p', '-E ot p']
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
        desc: 'Use temporary projects parent directory if not configured',
        usage: ['--projects-dir=/path/to/projects plan', '-l -P/path/to/projects p']
      }
    end

    def enforce_terra_versions?
      @optparse.on(
        '-V', '--disable-version-enforcement',
        'Disable enforcement of Terra* package version(s) in project configuration.'
      ) do
        @options[:enforce_versions] = false
      end
      @examples << {
        desc: 'Run plan without enforcing package version (using existing / system versions)',
        usage: ['-V plan']
      }
    end

    def enable_debug
      @optparse.on(
        '-d', '--debug',
        'Enable debug output for TerraUtils.'
      ) do
        @options[:debug] = true
      end
      @examples << {
        desc: 'Plan with debug output',
        usage: ['-d plan']
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
      print_command_only?
      upgrade_provider_versions?
      state_backend_auth_parameters
      env_auto_fill_parameters
      iac_framework
      add_projects_dir
      enforce_terra_versions?
      enable_debug
      versions_output
    end

    def default_examples
      # Must be in method to allow EXE_TARGET overwrite in tg
      [
        {
          desc: "Run #{self.class::EXE_TARGET} command (as configured) (e.g. apply)",
          usage: ['apply']
        },
        {
          desc: 'Run command via alias [if configured] (e.g. plan)',
          usage: ['p']
        },
        {
          desc: 'Print command for inspection',
          usage: ['-p plan']
        }
      ]
    end

    def generate_usage_examples
      desc_indent    = '  -'
      usage_indent   = '     '
      [default_examples, @examples].flatten.map do |example|
        [
          [desc_indent, example[:desc]].join(' '),
          example[:usage].map { |ue| [usage_indent, self.class::EXE_NAME, ue].join(' ') },
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
        #{self.class::EXE_NAME} - Executable for the TerraUtils utility using #{self.class::EXE_TARGET}

        CONFIGURATION
          Features can be enabled or disabled in config (default file:~/.config/terra_utils.json)
          - #{self.class::EXE_TARGET} command aliases
          - Automatic state backend provider authentication
          - Auto-filling environment variables for provider config (e.g. monitoring / alerting providers)

        USAGE
          #{self.class::EXE_NAME} [options] "[#{self.class::EXE_TARGET} command]"

      BANNER
    end

    def parse_options!
      @optparse.program_name = self.class::EXE_NAME
      set_banner
      @optparse.separator 'OPTIONS:'
      define_options
      help_output
      @optparse.parse!
    end
  end
end
