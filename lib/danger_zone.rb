#!/usr/bin/env ruby
# frozen_string_literal: true

## Log methods as made famous by Kenny Loggins
module DangerZone
  module_function # make following private instance variables but can DangerZone.log

  def lib_name(truncate: true)
    truncate ? self.class.name.split('::').first : self.class.name
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
    log(msg, 'DEBUG', lib_name(truncate: false))
  end
end
