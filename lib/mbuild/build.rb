require_relative 'base'

module Mbuild
  class Build < Base
    def initialize mruby, gem
      @dir = File.join(workdir, "build", mruby.name, gem.name)
      @mruby = mruby
      @gem = gem

      @config_path = File.join(@dir, "build_config.rb")
      @env = { "MRUBY_CONFIG" => self.config_path }
      @log_all = File.join(@dir, "all.txt")
      @log_test = File.join(@dir, "test.txt")

      FileUtils.makedirs @dir
    end

    attr_reader :config_path
    attr_reader :gem
    attr_reader :log_all
    attr_reader :log_test
    attr_reader :mruby
    attr_reader :result_all
    attr_reader :result_test

    def to_h
      {
          'mruby' => mruby.name,
          'mruby_url' => mruby.url,
          'mruby_hash' => mruby.hash,
          'gem' => (gem && gem.name),
          'gem_url' => (gem && gem.url),
          'gem_hash' => (gem && gem.hash),
          'gem_deps' => (gem && gem.deps),
          'result_all' => result_all,
          'result_test' => result_test
      }
    end

    def build
      mruby.clean
      build_all
      build_test
    end

    def clean
      mruby.clean
    end

    def build_all
      Dir.chdir @mruby.dir do
        puts "#{@mruby.name}/#{@gem.name}: rake all"
        File.open(@log_all, "w") do |f|
          pid = Process.spawn(@env, "rake all", { 1=>f, 2=>f })
          Process.waitpid pid
          @result_all = $?.success? ? :success : :failure
        end
      end
      @build_all_called = true
    end

    def build_test
      build_all unless @build_all_called

      unless @result_all == :success
        @result_test = :skipped
        return
      end

      Dir.chdir @mruby.dir do
        puts "#{@mruby.name}/#{@gem.name}: rake test"
        File.open(@log_test, "w") do |f|
          pid = Process.spawn(@env, "rake test", { 1=>f, 2=>f })
          Process.waitpid pid
          @result_test = $?.success? ? :success : :failure
        end
      end
    end

    def write_build_config
      File.open(self.config_path, "w") do |f|
        f.puts "MRuby::Build.new do |conf|"
        f.puts "  toolchain :gcc"
        f.puts "  conf.gembox 'default'"
        if @gem
          @gem.deps.each do |g|
            f.puts "  conf.gem :github => '#{g}'"
          end
          f.puts "  conf.gem '#{@gem.dir}'"
        end
        f.puts "end"
      end
    end
  end
end
