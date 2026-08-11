# /usr/bin/env ruby
# frozen_string_literal: true

require 'fileutils'
require_relative '../terragrunt_o_matic'

module TerraUtils
  # Standalone terragrunt-specific methoda
  module GruntHelpers
    module_function

    def delete_tg_cache
      log('Deleting Terragrunt cache...')
      FileUtils.rm_rf(File.join(Dir.pwd, '.terragrunt-cache'))
      log('... cache deleted!')
    end

    def sanitise_tg_source(src_str)
      # expecting e.g. "  source = \"git@gh:ll/tf.git//module/path\"\n"
      addr     = src_str.strip.gsub('source = ', '').delete('\"')
      path_arr = addr.gsub('//', '/').gsub(/\?ref=.*$/, '').split('/')
      # truncate repo
      repo = path_arr.find { |e| e.include?('.git') }.gsub('.git', '') # e.g. terraform
      # get path from repo
      [repo, path_arr[(path_arr.find_index { |e| e.include?('.git') } + 1)..]].flatten
    end

    def locate_correct_project_dir(repo)
      project_dir = @projects_dirs.find { |path| Dir.exist?(File.join(path, repo)) }
      raise ArgumentError, "Could not find #{repo} in any provided project dirs (#{@projects_dirs})" unless project_dir

      File.join(project_dir, repo)
    end

    def local_tg_source_path
      #hcl = File.read(File.join(Dir.pwd, 'terragrunt.hcl'))
      hcl = `terragrunt render`
      src = hcl.each_line.find { |l| l.include?('source =') }.strip

      src_path_arr = sanitise_tg_source(src)
      repo_dir     = locate_correct_project_dir(src_path_arr.first)
      File.join(repo_dir, *src_path_arr[1..])
    end

    def tg_source_switch
      [
        '--terragrunt-source',
        local_tg_source_path
      ].join(' ')
    end

    def tg_log_format(log_format_str)
      "--log-custom-format \"#{log_format_str}\""
    end

    def generate_init_upgrade_cmd(use_local_module: false)
      [
        'init -upgrade',
        (tg_source_switch if use_local_module)
      ].compact.join(' ')
    end

    def upgrade_providers_and_lock
      [
        @terra_cmd,
        generate_init_upgrade_cmd(use_local_module: @use_local_module),
        '&&',
        @terra_cmd,
        generate_providers_lock_cmd
      ]
    end
  end
end
