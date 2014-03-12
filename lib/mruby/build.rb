require 'fileutils'
require 'optparse'
require 'term/ansicolor'

require "mruby/build/version"
require "mruby/build/base"
require "mruby/build/mruby_repo"
require "mruby/build/mrbgem"
require "mruby/build/build"

class String
  include Term::ANSIColor
end

module Mruby
  module Build
    class InvalidCommandLineOptionError < StandardError; end
    module Method
      def run argv
        @pwd       = Dir.pwd
        @workdir   = ENV['MRUBY_BUILD_WORKDIR']
        @workdir ||= File.expand_path(File.dirname $0)
        @opts      = opt_parse argv

        MrubyRepo.pwd     = Mrbgem.pwd     = @pwd
        MrubyRepo.workdir = Mrbgem.workdir = @workdir
        MrubyRepo.opts    = Mrbgem.opts    = @opts

        repos   = load_mruby_list
        mrbgems = load_mgem_list
        if @opts[:base]
          repos.delete_if { |m| m.name != @opts[:base] }
        end
        if @opts[:gem]
          mrbgems.delete_if { |g| g.name != @opts[:gem] }
        end

        if @opts[:argv].size > 0
          dir  = @opts[:argv].shift
          name = File.basename dir
          g    = Mrbgem.local name, dir, *@opts[:argv]
          mrbgems = [g]
        end

        update repos, mrbgems
        results = build repos, mrbgems
        report results
      rescue InvalidCommandLineOptionError
        exit 1
      end

      def opt_parse argv
        build_options = {}

        opt = OptionParser.new
        opt.on('-a', '--all', 'build all combinations.') { |v| build_options[:all] = v }
        opt.on('-b MRUBY', '--base MRUBY') { |v| build_options[:base] = v }
        opt.on('-g GEM', '--gem GEM') { |v| build_options[:gem] = v }
        opt.on('-u', '--update') { |v| build_options[:update] = true }
        build_options[:argv] = opt.parse! argv

        unless build_options[:all] or build_options[:gem] or build_options[:argv].size > 0
          puts opt.help
          raise InvalidCommandLineOptionError
        end

        build_options
      end

      def load_mruby_list
        base = []
        base << MrubyRepo.new("mruby",  'git@github.com:mruby/mruby.git')
        base << MrubyRepo.new("stable", 'git@github.com:mruby-Forum/mruby.git')
        base << MrubyRepo.new("iij",    'git@github.com:iij/mruby.git')
        base
      end

      def load_mgem_list
        mrbgems = []
        mrbgems << Mrbgem.new("mruby-digest", 'git@github.com:iij/mruby-digest.git')
        mrbgems << Mrbgem.new("mruby-dir", 'git@github.com:iij/mruby-dir.git')
        mrbgems << Mrbgem.new("mruby-env", 'git@github.com:iij/mruby-env.git',
                              'iij/mruby-mtest', 'iij/mruby-regexp-pcre')
        mrbgems << Mrbgem.new("mruby-errno", 'git@github.com:iij/mruby-errno.git')
        mrbgems << Mrbgem.new("mruby-mdebug", 'git@github.com:iij/mruby-mdebug.git')
        mrbgems << Mrbgem.new2("iij/mruby-mock")
        mrbgems << Mrbgem.new("mruby-iijson", 'git@github.com:iij/mruby-iijson.git')
        mrbgems << Mrbgem.new("mruby-io", 'git@github.com:iij/mruby-io.git')
        mrbgems << Mrbgem.new("mruby-ipaddr", 'git@github.com:iij/mruby-ipaddr.git',
                              'iij/mruby-io', 'iij/mruby-pack', 'iij/mruby-socket',
                              'iij/mruby-env')
        mrbgems << Mrbgem.new2("iij/mruby-pack")
        mrbgems << Mrbgem.new2("iij/mruby-pcap")
        mrbgems << Mrbgem.new2("iij/mruby-process")
        mrbgems << Mrbgem.new2("iij/mruby-regexp-pcre")
        mrbgems << Mrbgem.new2("iij/mruby-require", 'iij/mruby-io', 'iij/mruby-dir',
                               'iij/mruby-tempfile')
        mrbgems << Mrbgem.new2("iij/mruby-simple-random")
        mrbgems << Mrbgem.new2("iij/mruby-socket", 'iij/mruby-io')
        mrbgems << Mrbgem.new("mruby-syslog", 'git@github.com:iij/mruby-syslog.git',
                              'iij/mruby-io')
        mrbgems << Mrbgem.new2("iij/mruby-tempfile", 'iij/mruby-io', 'iij/mruby-env')
        mrbgems
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
        builds = []
        repos.each { |m|
          mrbgems.each { |g|
            b = Build.new m, g
            b.write_build_config
            b.build
            builds << b
          }
        }
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
        puts "-" * 40

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
end
