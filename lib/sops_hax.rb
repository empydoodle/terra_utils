#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'

## Read SOPS-encrypted files
module SopsHax
  module_function

  def sops_encrypted?(path)
    # use `filestatus` to determine if encrypted
    json = JSON.parse(`sops filestatus #{path}`.strip, symbolize_names: true)
    json.fetch(:encrypted)
  rescue JSON::ParserError, KeyError
    false
  end

  def read_sops(path)
    # Use the `sops` command-line tool to read the secret
    File.read(`sops -d #{path}`.strip)
  end
end
