require_relative 'base'

module Mruby
  module Build
    class Build < Base
      def initialize mruby, gem, tick = nil
        @dir = File.join(workdir, "build", mruby.name, gem.name)
        @mruby = mruby
        @gem = gem
        @tick = tick if tick.is_a? Proc

        @config_path = File.join(@dir, "build_config.rb")
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

      def build
        Dir.chdir @mruby.dir

        env = { "MRUBY_CONFIG" => self.config_path }

        mruby.clean
        #$stdout.write "mruby/#{@gem.name}: rake all..."
        #$stdout.flush
        puts "#{@mruby.name}/#{@gem.name}: rake all"
        @tick.call if @tick
        File.open(@log_all, "w") { |f|
          pid = Process.spawn(env, "rake all", { 1=>f, 2=>f })
          Process.waitpid pid
          if $?.success?
            @result_all = :success
          else
            @result_all = :failure
          end
        }
        #$stdout.write "mruby/#{@gem.name}: rake all..."
        #$stdout.flush

        puts "#{@mruby.name}/#{@gem.name}: rake test"
        @tick.call if @tick
        if @result_all
          File.open(@log_test, "w") { |f|
            pid = Process.spawn(env, "rake test", { 1=>f, 2=>f })
            Process.waitpid pid
            if $?.success?
              @result_test = :success
            else
              @result_test = :failure
            end
          }
        else
          @result_test = :skipped
        end
      end

      def write_build_config
        File.open(self.config_path, "w") { |f|
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
        }
      end

    end
  end
end
