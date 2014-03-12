require_relative 'base'

module Mruby
  module Build
    class MrubyRepo < Base
      def initialize name, url
        @name    = name
        @url     = url

        @dir = File.join(workdir, @name)
        @upadted = false
      end

      attr_reader :dir
      attr_reader :name

      def clean
        system "rm -rf #{@dir}/build" unless opts[:update]
      end

      def update
        return if @updated
        if Dir.exists? @dir
          system "cd #{@dir} && git pull"
        else
          system "git clone -q #{@url} #{@dir}"
        end
        @updated = true
      end
    end
  end
end
