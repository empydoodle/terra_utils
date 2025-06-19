#!/usr/bin/env ruby
# frozen_string_literal: true

require 'optparse'
require_relative '../lib/terra_utils/terragrunt_o_matic/exe_options'
require_relative '../lib/terra_utils/terragrunt_o_matic/base'

parser = TerraUtils::TerragruntOMatic::ExeOptions.new
parser.parse_options!
TerraUtils::TerragruntOMatic::Base.new(parser.options, ARGV.to_a).run
