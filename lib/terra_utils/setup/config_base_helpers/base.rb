#!/usr/bin/env ruby
# frozen_string_literal: true

module TerraUtils
  module Setup
    module ConfigBaseHelpers
      # Helpers to populate main config
      module Base
        SCHEMA_PATH          = %w[base.json].freeze
        DEFAULT_PROJECT_DIRS = [
          File.join(Dir.home, 'projects'),
          File.expand_path(File.dirname(__FILE__, 6))
        ].uniq.freeze

        def generate_terra_utils_config(ind: 1)
          config = {}
          fetch_schema(*SCHEMA_PATH).each do |schema|
            config[schema.fetch(:name).to_sym] = setup_from_schema(schema, ind: ind, **config)
          end
          config
        end

        def setup_projects_dirs(ind: 2, **)
          args = { ref: 'project parent dir', options: DEFAULT_PROJECT_DIRS, path: true }
          user_config_options(**args, delimiter: ' ', ind: ind)
        end

        def setup_projects_settings(ind: 2, projects_dirs: [], **)
          ind += 1 # Method header is standalone section header
          config = { global: generate_project_config(:global, ind: ind) }
          additional_projects_header(ind)
          select_additional_projects(projects_dirs, ind: ind).each do |project|
            config[project.to_sym] = generate_project_config(project, ind: ind)
          end
          config
        end

        def additional_projects_header(ind = nil)
          header_txt = [
            'ADDITIONAL PROJECTS',
            'Project-specific configuration can be added to override the global configuration.'
          ]
          header_(header_txt, ind || 2)
        end

        def select_additional_projects(project_parent_dirs, ind: 3)
          project_parent_dirs.map do |source_dir|
            next unless Dir.exist?(source_dir)

            select_projects_from_parent_dir(source_dir, ind: ind)
          end.flatten
        end

        def select_projects_from_parent_dir(parent_dir, ind: 3)
          return [] unless parent_dir.is_a?(String) && !parent_dir.empty? && Dir.exist?(parent_dir)

          projects = fetch_project_options_from_parent_dir(parent_dir)
          return [] if projects.empty?

          args = { ref: "#{parent_dir} child project", options: projects, allow_empty: true }
          user_config_options(**args, ind: ind)
        end

        def fetch_project_options_from_parent_dir(project_parent_dir)
          paths = Dir.glob(File.join(project_parent_dir, '*')).select do |dir|
            File.directory?(dir) && Dir.entries(dir).include?('.git')
          end
          paths.reject! do |path|
            [
              Dir.glob(File.join(path, '**', '*.hcl')),
              Dir.glob(File.join(path, '**', '*.tf'))
            ].flatten.empty?
          end
          paths.map { |path| File.basename(path) }
        end
      end
    end
  end
end
