require_relative 'mruby_repo'
require_relative 'mrbgem_repo'
require 'mgem'

# XXX: hack
class MrbgemList
  include Enumerable
end
class MrbgemData
  def dependencies; @gem_data['dependencies']; end
end

module Mbuild
  class Config
    include Mrbgem

    def initialize default_config_path, user_config_path = nil
      if File.exist? default_config_path
        @default_config = TOML.load_file(default_config_path)
      end
      if File.exist? user_config_path
        @user_config = TOML.load_file(user_config_path)
      end

      @repos = parse_repos(@default_config) + parse_repos(@user_config)
      @mrbgems = parse_mrbgems(@default_config) + parse_repos(@user_config)
    end

    attr_reader :repos, :mrbgems

    private

    def parse_repos config
      repos = []
      return repos unless config

      config['mruby'].each do |name, info|
        repo_url = nil
        case info['repo']
        when /^github:/
          repo_url = info['repo'].sub(/^github:/, 'https://github.com/') + '.git'
        else
          repo_url = info['repo']
        end if info['repo']
        branch = info['branch']

        repos << MrubyRepo.new(name, repo_url, branch)
      end

      repos
    end

    def parse_mrbgems config
      mrbgems = []
      return mrbgems unless config

      mgem_names = config['mrbgem']['mgem'] || []
      load_gems.each do |mgem|
        if mgem_names.include? mgem.name
          name     = mgem.name
          repo_url = mgem.repository
          deps     = [mgem.dependencies].flatten.compact
          mrbgems << MrbgemRepo.new(name, repo_url, *deps)
        end
      end

      config['mrbgem'].each do |name, info|
        next if name == 'mgem'
        deps = [info['dependencies']].flatten.compact
        mrbgem = mrbgems.find{|m| m.name == name }
        if mrbgem
          repo_url = mrbgem.url
          deps = [deps, mrbgem.deps].flatten.compact
          mrbgems.delete mrbgem
          mrbgems << MrbgemRepo.new(name, repo_url, *deps)
        else
          repo_url = nil
          case info['repo']
            when /^github:/
              repo_url = info['repo'].sub(/^github:/, 'https://github.com/') + '.git'
            else
              repo_url = info['repo']
          end if info['repo']

          mrbgems << MrbgemRepo.new(name, repo_url, *deps)
        end
      end

      mrbgems
    end
  end
end
