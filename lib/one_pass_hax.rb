#!/usr/bin/env ruby
# frozen_string_literal: true

## Retrieve entries from 1Password
module OnePassHax
  module_function

  def fetch_op_secret(path)
    # Use the `op` command-line tool to read the secret
    `op read "op://#{path.gsub('op://', '')}"`.strip
  end
end
