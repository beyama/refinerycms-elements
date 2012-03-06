module Elements
  autoload :Types,                    'elements/types'
  autoload :Compiler,                 'elements/compiler'
  autoload :CompilerMiddleware,       'elements/compiler_middleware'
  autoload :ElementArray,             'elements/element_array'
  autoload :ElementBuilder,           'elements/element_builder'
  autoload :HasManyElements,          'elements/has_many_elements'
  autoload :Commons,                  'elements/commons'
  autoload :PagesControllerExtension, 'elements/pages_controller_extension'
  autoload :ActionViewExtension,      'elements/action_view_extension'
  autoload :ElementMethods,           'elements/element_methods'

  class TypeError < ::TypeError; end

  attr_accessor :widgets

  def self.widgets
    @widgets ||= []
  end

  class Widget
    
    def self.register(name = nil, supported_types = nil, &block)
      widget = self.new(name, supported_types)

      yield widget if block_given?

      raise "A widget MUST have a name!: #{widget.inspect}" if widget.name.blank?
      raise "A widget MUST have supported_types!: #{widget.inspect}" if widget.supported_types.blank?
    end

    attr_accessor :name, :supported_types

    def initialize(name, supported_types)
      self.name = name.to_s.camelcase if name.present?
      self.supported_types = supported_types

      ::Elements.widgets << self
    end
    protected :initialize

    def partial
      "admin/elements/widgets/#{self.name.underscore}" 
    end

  end

end
