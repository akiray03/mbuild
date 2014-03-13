require_relative 'mruby_repo'
require_relative 'mrbgem_repo'
require 'mgem'

module Mbuild
  class Config
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

    private

    def parse_repos config
      []
    end

    def parse_mrbgems config
      []
    end
  end
end