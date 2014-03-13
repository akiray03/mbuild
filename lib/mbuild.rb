require 'fileutils'
require 'optparse'
require 'term/ansicolor'
require 'ruby-progressbar'
require 'toml'
require 'mgem'

require "mbuild/version"
require "mbuild/base"
require "mbuild/mruby_repo"
require "mbuild/mrbgem_repo"
require "mbuild/build"
require "mbuild/config"

class String
  include Term::ANSIColor
end

module Mbuild
  class InvalidCommandLineOptionError < StandardError; end
  module Method
    def run argv
      @pwd       = Dir.pwd
      @workdir   = File.expand_path(ENV['MBUILD_WORKDIR'] || Dir.pwd)
      @opts      = opt_parse argv
      @parallels = (ENV['MBUILD_PARALLEL'] || 1).to_i
      default_config_path = File.expand_path('../default.conf', __FILE__)
      user_config_path = ENV['MBUILD_CONFIG'] || File.join(ENV['HOME'], '.mbuild.conf')
      @config = Config.new default_config_path, user_config_path

      Build.pwd     = MrubyRepo.pwd     = MrbgemRepo.pwd     = @pwd
      Build.workdir = MrubyRepo.workdir = MrbgemRepo.workdir = @workdir
      Build.opts    = MrubyRepo.opts    = MrbgemRepo.opts    = @opts

      repos   = load_mruby_list
      mrbgems = load_mgem_list
      if @opts[:base].size > 0
        repos = repos.select{|r| @opts[:base].include? r.name}
      end
      if @opts[:gem].size > 0
        mrbgems = mrbgems.select{|m| @opts[:gem].include? m.name }
      end

      if @opts[:argv].size > 0
        dir  = @opts[:argv].shift
        name = File.basename dir
        g    = MrbgemRepo.local name, dir, *@opts[:argv]
        mrbgems = [g]
      end

      buildinfo repos, mrbgems
      update repos, mrbgems
      results = build repos, mrbgems
      report results
    rescue InvalidCommandLineOptionError
      exit 1
    end

    def opt_parse argv
      build_options = {
          all: false,
          base: [],
          gem: [],
          update: false,
          argv: []
      }

      opt = OptionParser.new
      opt.on('-a', '--all', 'build all combinations.') { |v| build_options[:all] = v }
      opt.on('-b MRUBY', '--base MRUBY') { |v| build_options[:base] << v }
      opt.on('-g GEM', '--gem GEM') { |v| build_options[:gem] << v }
      opt.on('-u', '--update') { |v| build_options[:update] = true }
      build_options[:argv] = opt.parse! argv

      unless build_options[:all] or build_options[:gem].size > 0 or build_options[:argv].size > 0
        puts opt.help
        raise InvalidCommandLineOptionError
      end

      build_options
    end

    def load_mruby_list
      base = []
      base << MrubyRepo.new("mruby",  'https://github.com/mruby/mruby.git')
      base << MrubyRepo.new("stable", 'https://github.com/mruby-Forum/mruby.git')
      base << MrubyRepo.new("iij",    'https://github.com/iij/mruby.git')
      base
    end

    def load_mgem_list
      mrbgems = []
      mrbgems << MrbgemRepo.new("mruby-digest", 'https://github.com/iij/mruby-digest.git')
      mrbgems << MrbgemRepo.new("mruby-dir", 'https://github.com/iij/mruby-dir.git')
      mrbgems << MrbgemRepo.new("mruby-env", 'https://github.com/iij/mruby-env.git',
                            'iij/mruby-mtest', 'iij/mruby-regexp-pcre')
      mrbgems << MrbgemRepo.new("mruby-errno", 'https://github.com/iij/mruby-errno.git')
      mrbgems << MrbgemRepo.new("mruby-mdebug", 'https://github.com/iij/mruby-mdebug.git')
      mrbgems << MrbgemRepo.new2("iij/mruby-mock")
      mrbgems << MrbgemRepo.new("mruby-iijson", 'https://github.com/iij/mruby-iijson.git')
      mrbgems << MrbgemRepo.new("mruby-io", 'https://github.com/iij/mruby-io.git')
      mrbgems << MrbgemRepo.new("mruby-ipaddr", 'https://github.com/iij/mruby-ipaddr.git',
                            'iij/mruby-io', 'iij/mruby-pack', 'iij/mruby-socket',
                            'iij/mruby-env')
      mrbgems << MrbgemRepo.new2("iij/mruby-pack")
      mrbgems << MrbgemRepo.new2("iij/mruby-pcap")
      mrbgems << MrbgemRepo.new2("iij/mruby-process")
      mrbgems << MrbgemRepo.new2("iij/mruby-regexp-pcre")
      mrbgems << MrbgemRepo.new2("iij/mruby-require", 'iij/mruby-io', 'iij/mruby-dir',
                             'iij/mruby-tempfile')
      mrbgems << MrbgemRepo.new2("iij/mruby-simple-random")
      mrbgems << MrbgemRepo.new2("iij/mruby-socket", 'iij/mruby-io')
      mrbgems << MrbgemRepo.new("mruby-syslog", 'https://github.com/iij/mruby-syslog.git',
                            'iij/mruby-io')
      mrbgems << MrbgemRepo.new2("iij/mruby-tempfile", 'iij/mruby-io', 'iij/mruby-env')
      mrbgems
    end

    def buildinfo repos, mrbgems
      puts "* Build Information (mruby)".yellow
      repos.each do |r|
        puts "#{r.name.ljust(20)}#{r.url}"
      end
      puts

      puts "* Build Information (mrbgem)".yellow
      mrbgems.each do |m|
        puts "#{m.name.ljust(20)}#{m.url}"
      end
      puts
    end

    def update repos, mrbgems
      repos.each do |m|
        puts "* updating #{m.name}/mruby".yellow
        m.update
      end

      mrbgems.each do |g|
        puts "* updating #{g.name}".yellow
        g.update
      end
    end

    def build repos, mrbgems
      puts
      puts "* Build and test".yellow
      progressbar = ProgressBar.create(
          title: 'Builds',
          format: '%B(%p%%)',
          progress_mark: ' ',
          remainder_mark: ' ',
          starting_at: 0,
          total: (repos.size * mrbgems.size * 2)
      )
      builds = []
      mrbgems.each do |g|
        repos.each do |m|
          b = Build.new m, g
          b.write_build_config
          b.clean
          b.build_all
          progressbar.increment
          b.build_test
          progressbar.increment
          builds << b
        end
      end
      builds
    end

    def report results
      def result_to_str result
        case result
        when :success
          "ok      ".green
        when :failure
          "failed  ".red
        when :skipped
          "skipped ".magenta
        else
          "???     ".on_blue
        end
      end

      puts
      puts "Build Results:".yellow
      puts "%-7s %-20s %-8s%s" % [ "mruby", "mrbgem", "build", "test" ]
      puts "-" * 48

      results.sort! { |a, b|
        if a.gem.name == b.gem.name
          a.mruby.name <=> b.mruby.name
        else
          a.gem.name <=> b.gem.name
        end
      }
      results.each do |b|
        l =  "%-7s " % b.mruby.name
        l += "%-20s " % b.gem.name
        l += result_to_str(b.result_all) + result_to_str(b.result_test)
        puts l
      end
    end
  end
  extend Method
end
