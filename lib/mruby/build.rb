require 'fileutils'
require 'optparse'
require 'term/ansicolor'

require "mruby/build/version"

class String
  include Term::ANSIColor
end

module Mruby
  module Build
    def self.run argv
      p argv
    end
  end
end
