#!/usr/bin/env ruby
# frozen_string_literal: true

module TerraUtils
  module Setup
    ## Executable file helpers for TerraUtils setup
    module ExeFileHelpers
      def setup_exe_symlink(src_exe:, default_exe_name:, dir: USER_EXECUTABLES_DIR, ind: 1)
        src_path = File.join(T_U_EXECUTABLES_DIR, src_exe)
        exe_path = File.join(dir, default_exe_name)
        say_("Checking state of target path for #{src_exe} (#{exe_path})...", ind)
        exe_path = resolve_exe_symlink(src_path, exe_path, ind: ind + 1)
        return src_path unless exe_path

        say_("Creating symlink for [#{exe_file}] at: #{exe_path[:path]}", ind)
        create_link(exe_path, src_path)
      end

      def resolve_exe_symlink(src_path, exe_path, ind: 2)
        return exe_path unless File.exist?(exe_path) # Confirm path unless unavailable

        if File.symlink?(exe_path)
          return nil if File.readlink(exe_path) == src_path # Symlink already correct

          # Symlink exists but points to different file - ask user how to proceed
          raise(SetupError, "Intended path for symlink already in use (#{exe_path} => #{File.readlink(exe_path)})")
        end
        # File exists at symlink target - rename symlink
        say_("File already exists at exe symlink target! (#{exe_path})", ind, :red)
        rename_exe(path: exe_path, ind: ind + 1)
      rescue SetupError => e
        error_(e.message, ind)
        exe_path = handle_existing_exe_symlink(path: exe_path, ind: ind + 1)
        retry
      end

      def rename_exe(path, ind: 3)
        # Rename executable file if file exists / user opts to do so
        exe_name = ask_('Please specify new full name for executable (e.g. tg)', ind)
        raise SetupError, 'Executable name cannot be blank!' if exe_name.empty?

        new_path = File.join(File.dirname(path), exe_name)
        raise SetupError, "File already exists! (#{new_path})" if File.exist?(new_path)

        new_path
      rescue SetupError => e
        error_(e.message, ind)
        retry
      end

      def handle_existing_exe_symlink(path:, ind: 3)
        # Act based on user decision
        option = ask_symlink_handling(path: path, ind: ind)
        case option
        when 1
          # Overwrite
          say_("Unlinking existing symlink for #{path}", ind)
          remove_file(path).first
        when 2
          # Rename
          rename_exe(path, ind: ind + 1)
        when 3
          # Do nothing
          say_('Skipping executable creation', ind, :yellow)
          nil
        else
          # Error + retry
          raise SetupError, "Invalid option selected: #{option} - please select 1, 2 or 3"
        end
      rescue SetupError => e
        error_(e.message, ind)
        retry
      end

      def ask_symlink_handling(path:, ind: 3)
        # Decide course of action in event that executable symlink already exists
        say_('Please select one of the following options to proceed:', ind)
        options = [
          "1) Overwrite existing symlink (unlink existing #{path} file)?",
          '2) Use different name for executable?',
          "3) Do nothing (do not create executable in #{File.dirname(path)})?"
        ]
        say_(options, ind + 1)
        ask_('(1-3)', ind).to_i
      end
    end
  end
end
