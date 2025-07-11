#!/usr/bin/env ruby
# frozen_string_literal: true

module TerraUtils
  module Setup
    ## Configuration file helpers for TerraUtils setup
    module ConfigFileHelpers
      def setup_config_file(schema, ind: 1, **options)
        config    = schema.fetch(:config)
        dir, path = generate_file_attributes(config)
        say_("Checking for #{schema.fetch(:nice_name)} config (#{path})...", ind)
        return path if config_file_exists?(path, ind + 1)

        empty_directory(dir) unless Dir.exist?(dir)
        return copy_config_template(config.fetch(:config_template), path, ind) if use_config_template?(schema, ind)

        generate_config_file(path: path, schema: schema, ind: ind, **options)
      end

      def generate_file_attributes(schema_config)
        file = schema_config.fetch(:config_file)
        dir  = File.dirname(file) == '.' ? @config_dir : File.expand_path(File.dirname(file))
        [dir, File.join(dir, File.basename(file))]
      rescue KeyError => e
        error_("Error retrieving setup data from schema: #{e.message}")
        debug_(e)
      end

      def generate_config_file(path:, schema:, ind: 1, **options)
        method = "generate_#{schema.fetch(:name)}_config".to_sym
        say_("Preparing config generator for #{path} (#{method})... ", ind, :leading_br)
        config = public_send(method.to_sym, ind: ind + 1, schema: schema, **options)
        say_("Config generator finished! (#{method})", ind, :green, :leading_br)
        say('Writing config to file...', ind)
        create_file(path, JSON.pretty_generate(config))
        say_('... done!', ind)
        config
      end

      def config_file_exists?(path, ind = nil)
        return false unless File.exist?(path)

        say_('File exists!', ind, :yellow)
        return true unless yes_?("Back up and overwrite existing config (#{path})?", ind)

        require 'date'
        timestamp = DateTime.now.iso8601.gsub(/\W/, '')[0..-5]
        backup    = path.dup.insert(-6, ".bk.#{timestamp}")
        backup_config_file(path, backup, ind: ind)
        false
      end

      def backup_config_file(src_path, backup_path, ind: 3)
        source_paths.unshift(File.dirname(src_path))
        copy_file(File.basename(src_path), backup_path)
        remove_file(src_path)
        source_paths.delete(File.dirname(src_path))
        say_("Backed up existing config to #{backup_path}", ind)
      end

      def use_config_template?(schema, ind = nil)
        return false unless schema.dig(*%i[config config_template])
        return true if schema.dig(*%i[config force_config_template])

        say_('INFO: "No" response will copy a config template instead', ind, :yellow, :leading_br)
        no_?("Use config wizard to populate #{schema.fetch(:nice_name)} config?", ind)
      end

      def copy_config_template(template, path, ind = nil)
        say_("Copying config file template to #{path}", ind)
        copy_file(template, path)
        path
      end
    end
  end
end
