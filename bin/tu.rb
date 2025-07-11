#!/usr/bin/env ruby
# frozen_string_literal: true

require 'optparse'
require_relative '../lib/terra_utils/exe_options'
require_relative '../lib/terra_utils/base'

parser = TerraUtils::ExeOptions.new
parser.parse_options!
TerraUtils::Base.new(parser.options, ARGV.to_a).run
