#!/usr/bin/env ruby
# frozen_string_literal: true

module TerraUtils
  module Setup
    # Helpers to populate main config
    module ConfigBaseHelpers
      DEFAULT_PROVIDER_PLATFORMS = %w[linux_amd64 linux_arm64 darwin_amd64 darwin_arm64 windows_amd64].freeze
      DEFAULT_PROJECT_DIRS       = [
        File.join(Dir.home, 'projects'),
        File.expand_path(File.dirname(__FILE__, 5))
      ].uniq.freeze

      def setup_provider_lock_platforms(ind: 2)
        header = ['TERRAFORM PROVIDER LOCK PLATFORMS', 'Set the platforms for which provider binaries will be locked.']
        header_(header, ind)
        args = { ref: 'terraform provider platform', default: DEFAULT_PROVIDER_PLATFORMS, with_custom: true }
        user_config_options(**args, ind: ind)
      end

      def setup_project_parent_dirs(ind: 2)
        header = [
          'PROJECT PARENT DIRECTORIES',
          'Set the standard directories in which you store your Terraform / Terragrunt projects'
        ]
        header_(header, ind)
        args = { ref: 'project parent dir', default: DEFAULT_PROJECT_DIRS, with_custom: true, path: true }
        user_config_options(**args, ind: ind)
      end

      def prompt_directory_structure(dir_level: 0, dir_structure: [], ind: 2)
        hint = 'HINT: Speed up this step by entering /-separated values, e.g. client/env/namespace/module'
        say_(hint, ind, :blue)
        prompt = "Please enter the directory scope for level #{dir_level} (e.g. module, env)"
        scopes = user_option_prompt(prompt_override: prompt, ind: ind, escape: !dir_level.zero?).split('/')
        dir_structure.push(scopes.reject(&:empty?)).flatten!
        if prompt_additional_configs(ref: 'project dir scope', selected_options: dir_structure, list_index: true, ind: ind)
          prompt_directory_structure(dir_level: dir_structure.size, dir_structure: dir_structure, ind: ind)
        end
        dir_structure
      end

      def setup_directory_structure(ind: 2)
        header = [
          'PROJECT DIRECTORY STRUCTURE',
          'TerraUtils relies on context/scope of the directory structure of your projects to function at its best.',
          '  i.e. the scope of directories inside your project until the main.tf or terragrunt.hcl files.',
          'For example:',
          '  - module/',
          '  - environment/module/',
          '  - region/client/environment/module/'
        ]
        header_(header, ind)
        prompt_directory_structure(ind: ind + 1)
      end

      def setup_versions(ind: 2)
        header = ['VERSIONS', 'Set the versions of Terraform and Terragrunt to use in the target project.']
        header_(header, ind)
        {
          'terraform' => user_option_prompt(prompt_override: 'Please enter Terraform version to use', ind: ind),
          'terragrunt' => user_option_prompt(prompt_override: 'Please enter Terragrunt version to use', ind: ind)
        }
      end

      def fetch_project_options_from_project_dir(project_dir)
        paths = Dir.glob(File.join(project_dir, '*')).select do |dir|
          File.directory?(dir) && Dir.entries(dir).include?('.git')
        end
        paths.reject do |path|
          [
            Dir.glob(File.join(path, '**', '*.hcl')),
            Dir.glob(File.join(path, '**', '*.tf'))
          ].flatten.empty?
        end
      end

      def select_projects_from_project_dir(project_dir, ind: 2)
        return [] unless project_dir.is_a?(String) && !project_dir.empty? && Dir.exist?(project_dir)

        paths = fetch_project_options_from_project_dir(project_dir)
        return [] if paths.empty?

        projects = paths.map { |path| File.basename(path) }
        args     = { ref: "parent directory #{project_dir} child project", default: projects, with_custom: true }
        user_config_options(**args, ind: ind)
      end

      def fetch_projects_from_project_dirs(project_dirs: [], ind: 2)
        return [] unless project_dirs.is_a?(Array) && !project_dirs.empty?

        project_dirs.flat_map do |pd|
          next nil unless Dir.exist?(pd)

          select_projects_from_project_dir(pd, ind: ind)
        end.compact.uniq
      end

      def gather_additional_projects(project_dirs, ind: 2)
        header = [
          'ADDITIONAL PROJECTS',
          'Project-specific configuration can be added to override the global configuration.'
        ]
        header_(header, ind)
        fetch_projects_from_project_dirs(project_dirs: project_dirs, ind: ind)
      end

      def override_setting_for_project?(project:, setting:, ind: 2)
        return true if project == 'global'

        prompt = "Create '#{setting}' config override for project '#{project}'?"
        user_switch_prompt(prompt_override: prompt, ind: ind, bold: false)
      end

      def setup_project_basic_settings(project, ind: 2)
        [
          if override_setting_for_project?(project: project, setting: 'directory_structure', ind: ind)
            ['directory_structure', setup_directory_structure(ind: ind)]
          end,
          if override_setting_for_project?(project: project, setting: 'versions', ind: ind)
            ['versions', setup_versions(ind: ind)]
          end
        ].compact.to_h
      end

      def setup_project_settings(project:, ind: 2)
        header = project == 'global' ? 'GLOBAL PROJECT SETTINGS' : "PROJECT SETTINGS (#{project})"
        header_(header, ind, :tall, :parag)
        settings = setup_project_basic_settings(project, ind: ind + 1)
        features = setup_project_features(project, ind: ind + 1)
        features.empty? ? settings : settings.merge({ 'features' => features })
      end

      def base_config_prompts(ind: 2)
        {
          'terraform_provider_platforms' => setup_provider_lock_platforms(ind: ind),
          'projects_dirs' => setup_project_parent_dirs(ind: ind),
          'projects_settings' => {
            'global' => setup_project_settings(project: 'global', ind: ind)
          }
        }
      end

      def setup_base_config(ind: 1)
        config = base_config_prompts(ind: ind + 1)
        gather_additional_projects(config.fetch('projects_dirs', ind: ind + 1)).map do |project|
          config['projects_settings'][project] = setup_project_settings(project: project, ind: ind + 1)
        end
        config
      end
    end
  end
end
