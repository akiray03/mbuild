require 'fileutils'
require 'optparse'
require 'term/ansicolor'

require "mruby/build/version"
require "mruby/build/mruby"
require "mruby/build/mrbgem"
require "mruby/build/build"

class String
  include Term::ANSIColor
end

module Mruby
  module Build
    class InvalidCommandLineOptionError < StandardError; end

    def run argv
      @pwd = Dir.pwd
      @workdir = File.expand_path(File.dirname $0)
      @opts = opt_parse argv
      p @pwd, @workdir, @opts
    rescue InvalidCommandLineOptionError
      exit 1
    end
    module_function :run

    def opt_parse argv
      build_options = {}

      opt = OptionParser.new
      opt.on('-a', '--all', 'build all combinations.') { |v| build_options[:all] = v }
      opt.on('-b MRUBY', '--base MRUBY') { |v| build_options[:base] = v }
      opt.on('-g GEM', '--gem GEM') { |v| build_options[:gem] = v }
      opt.on('-u', '--update') { |v| build_options[:update] = true }
      arguments = opt.parse argv

      unless build_options[:all] or build_options[:gem] or arguments.size > 0
        puts opt.help
        raise InvalidCommandLineOptionError
      end

      build_options
    end
    module_function :opt_parse
  end
end
