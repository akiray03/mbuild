require_relative 'base'

module Mbuild
  class Mrbgem < Base
    def initialize name, url, *deps
      @name = name
      @url  = url
      @deps = deps

      @dir = File.join(workdir, @name)
      @updated = false
    end

    def self.new2 repo, *deps
      name = repo.sub(/^.*\//, "")
      url = "git@github.com:#{repo}.git"
      self.new name, url, *deps
    end

    def self.local name, dir, *deps
      g = self.new name, "", *deps
      g.set_dir File.join(pwd, dir)
      g
    end

    attr_reader :deps
    attr_reader :dir
    attr_reader :name
    attr_reader :url

    def set_dir dir
      @dir = dir
    end

    def update
      return if @updated
      if Dir.exists? @dir
        system "cd #{@dir} && git fetch --depth 1 origin"
        system "cd #{@dir} && git checkout master"
      else
        system "git clone -q --depth 1 #{@url} #{@dir}"
      end
      @updated = true
    end
  end
end
