module Mruby
  module Build
    class Mruby
      def initialize name, url
        @name    = name
        @url     = url

        @dir = File.join($workdir, @name)
        @upadted = false
      end

      attr_reader :dir
      attr_reader :name

      def clean
        system "rm -rf #{@dir}/build" unless $opts[:update]
      end

      def update
        return if @updated
        if Dir.exists? @dir
          Dir.chdir @dir
          system "git pull"
        else
          system "git clone #{@url} #{@dir}"
        end
        @updated = true
      end
    end
  end
end
