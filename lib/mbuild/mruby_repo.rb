require_relative 'base'

module Mbuild
  class MrubyRepo < Base
    def initialize name, url, branch = nil
      @name    = name
      @url     = url
      @branch  = branch

      @dir = File.join(workdir, @name)
      @upadted = false
    end

    attr_reader :dir
    attr_reader :name
    attr_reader :url
    attr_reader :branch

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
      if @branch
        system "cd #{@dir} && git checkout #{@branch}"
      end
      @updated = true
    end
  end
end
