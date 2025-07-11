#!/usr/bin/env ruby
# frozen_string_literal: true

## Log methods as made famous by Kenny Loggins
module DangerZone
  module_function # make following private instance variables but can DangerZone.log

  def lib_name(truncate: 0)
    name = self.class == Module ? self.name : self.class.name
    truncate ? name.split('::')[truncate] : name
  end

  def debug_mode?
    instance_variable_get(:@debug) || lib_name == 'DangerZone'
  end

  def log(msg, tag = nil, lib = nil)
    tag ||= 'INFO'
    lib ||= lib_name
    log_str = "[#{Time.now}][#{lib.upcase}][#{tag}] #{msg}"
    tag == 'ERR' ? warn(log_str) : $stdout.puts(log_str)
    msg
  end

  def log_err(msg, err_obj = nil)
    msg_str = [
      "#{msg}:",
      begin
        err_obj.message
      rescue StandardError
        nil
      end,
      err_obj.inspect
    ].compact.join("\n")
    log(msg_str, 'ERR')
  end

  def log_debug(msg)
    return nil unless debug_mode?

    log(msg, 'DEBUG', lib_name(truncate: false))
  end

  def silent_cmd(cmd, silence_stderr: true)
    silence_stderr = false if debug_mode?
    cmd = [
      cmd,
      ('2&>1' if silence_stderr),
      '> /dev/null'
    ].flatten.compact
    system(cmd.join(' '))
  end
end
