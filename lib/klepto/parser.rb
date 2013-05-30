module Klepto
  module Parser
    def self.included(klass)
      klass.extend ClassMethods
    end

    def call(node)
      node.try(:text)
    end

    module ClassMethods
    end
  end
end


