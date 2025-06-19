#!/usr/bin/env ruby
# frozen_string_literal: true

module TerraUtils
  module Setup
    ## Configuration file helpers for TerraUtils setup
    module ConfigFileHelpers
      def backup_config_file(path, ind: 3)
        require 'date'
        timestamp = DateTime.now.iso8601.gsub(/\W/, '')[0..-5]
        backup    = path.dup.insert(-6, ".bk.#{timestamp}")
        source_paths.unshift(File.dirname(path))
        copy_file(File.basename(path), backup)
        remove_file(path)
        source_paths.delete(File.dirname(path))
        say_("Backed up existing config to #{backup}", ind)
      end

      def check_existing_config(path, ind: 2)
        return false unless File.exist?(path)

        say_('File exists!', ind, :yellow)
        return true unless yes_?("Back up and overwrite existing config (#{path})?", ind)

        backup_config_file(path, ind: ind)
        false
      end

      def copy_config_template(file:, path:, ind: 2)
        say_("Copying config file template to #{path}", ind)
        copy_file(file, path)
        path
      end

      def use_config_template?(config_name, force_template: false, ind: 1)
        return true if force_template

        say_('INFO: "No" response will copy a config template instead', ind, :yellow, leading_br: true)
        no_?("Use config wizard to populate #{config_name} config?", ind)
      end

      def setup_config_file(name:, file:, method:, ind: 1, **options)
        dir  = File.dirname(file) == '.' ? @config_dir : File.dirname(file)
        path = File.join(dir, File.basename(file))
        say_("Checking for #{name} config (#{path})...", ind)
        return path if check_existing_config(path, ind: ind + 1)

        empty_directory(dir) unless Dir.exist?(dir)
        if use_config_template?(name, force_template: options.delete(:force_config_template), ind: ind)
          return copy_config_template(file: file, path: path, ind: ind)
        end

        create_file(path, JSON.pretty_generate(public_send(method.to_sym, ind: ind, **options)))
      end

      def setup_base_config_file(ind: 1)
        args = {
          name: 'Terra Utils',
          file: 'terra_utils.json',
          method: :setup_base_config
        }
        setup_config_file(**args, ind: ind)
      end
    end
  end
end
