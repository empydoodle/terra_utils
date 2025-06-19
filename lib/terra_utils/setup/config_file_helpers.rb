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

      def setup_config_file(name:, file:, method:, ind: 1)
        path = File.join(@config_dir, file)
        say_("Checking for #{name} config (#{path})...", ind)
        return path if check_existing_config(path, ind: ind + 1)

        empty_directory(@config_dir) unless Dir.exist?(@config_dir)
        say_('INFO: "No" response will copy a config template instead', ind, :yellow, leading_br: true)
        use_config_template = no_?("Use config wizard to populate #{name} config?", ind)
        return copy_config_template(file: file, path: path, ind: ind) if use_config_template

        create_file(path, JSON.pretty_generate(public_send(method.to_sym, ind: ind)))
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
