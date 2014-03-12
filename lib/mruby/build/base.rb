module Mruby
  module Build
    class Base
      class << self
        attr_accessor :workdir, :opts, :pwd
      end
      def workdir
        self.class.workdir
      end
      def opts
        self.class.opts
      end
      def pwd
        self.class.pwd
      end
    end
  end
end
