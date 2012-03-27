require 'refinerycms-core'
require 'acts_as_list'
require 'apotomo'
require 'i18n-js'

Apotomo.js_framework = :jquery

module Elements
  require 'elements/action_view_extension'
  require 'elements/engine'

  autoload :Types,                    'elements/types'
  autoload :Compiler,                 'elements/compiler'
  autoload :CompilerMiddleware,       'elements/compiler_middleware'
  autoload :ElementArray,             'elements/element_array'
  autoload :ElementBuilder,           'elements/element_builder'
  autoload :HasManyElements,          'elements/has_many_elements'
  autoload :Commons,                  'elements/commons'
  autoload :PagesControllerExtension, 'elements/pages_controller_extension'
  autoload :ElementMethods,           'elements/element_methods'
  autoload :Testing,                  'elements/testing'

  class TypeError < ::TypeError; end

  class << self
    def root
      @root ||= Pathname.new(File.expand_path('../../', __FILE__))
    end

    def factory_paths
      @factory_paths ||= [ root.join("spec/factories").to_s ]
    end
  end

end
