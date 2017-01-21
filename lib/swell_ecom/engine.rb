
require 'stripe'
require 'tax_cloud'

module SwellEcom
  class Engine < ::Rails::Engine
    isolate_namespace SwellEcom
  end
end
