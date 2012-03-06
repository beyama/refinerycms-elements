/**
 * Refinerycms Elements Editor
 * (c) 2011 Alexander Jentz, beyama.de.
 *
 * Refinerycms Elements may be freely distributed under the MIT license.
 */
$(function() {

  /** Some context locals */
  var t = {}, // Templates
      h = {}, // Helper
      w = {}, // Widgets
      e = {}; // Elements

  /** 
   * Mustache template helper function.
   *
   * @param String Mustache template
   * @return Function
   */
  h.mustacheTemplate = function(template) {
    return function(view, partials) {
      return Mustache.to_html(template, view, partials);
    };
  };

  h.inheritEvents = function(baseclass, events) {
    return function() {
      var self = this;
      function getEvents(events) {
        if(typeof events === 'function')
          return events.call(self);
        return events;
      };

      return _.extend({}, getEvents(baseclass.prototype.events), getEvents(events));
    };
  };

  h.scrollToWidget = function(widget) {
    $('html,body').animate({ scrollTop: $(widget.el).offset().top }, 1000);
  };

  h.extractDataFromImageDialog = function(image) {
    var image = $(image);

    return {
      id: image.attr('id').replace("image_", ""),
      thumbnail: image.attr('src'),
      thumbnail_large: image.data('large'),
      thumbnail_medium: image.data('medium'),
      thumbnail_small: image.data('small'),
      original: image.data('original'),
      image_name: image.attr('title')
    };
  };

  window.Elements = {
    /**
     * Generates element descriptors from JSON data
     */
    init: function(data) {
      this.descriptors = Elements.DescriptorCollection.fromJSON(data);
      this.elements = Elements.Element.buildModelClassesFromDescriptors(this.descriptors);
    },

    getElement: function(name) {
      return this.elements[name];
    }
  };

  /** 
   * Descriptor model 
   * 
   * Attributes:
   * * name: Name of descriptor
   * * title: Title of descriptor
   * * description: Description of descriptor
   * * parent: Object with `name` attribute holding the name of parent descriptor
   * * properties: Properties collection
   */
  Elements.Descriptor = Backbone.Model.extend({
    /**
     * Find all descendants of `this` descriptor.
     *
     * @return {Array}
     */
    descendants: function() {
      var children = [],
          baseName = this.get('name');

      this.collection.each(function(desc) { 
        var parent = desc.get('parent');
        if(parent && parent.get('name') === baseName) {
          children.push(desc);
          var descendants = desc.descendants();
          if(descendants.length)
            children = children.concat(descendants);
        }
      });
      return children;
    }
  }, { modelName: 'Descriptor' });

  /** Descriptor model collection */
  Elements.DescriptorCollection = Backbone.Collection.extend({
    model: Elements.Descriptor,

    /**
     * Find descriptor by name.
     *
     * @param {String}
     * @return {RefineryElements.Descriptor}
     */
    findByName: function(name) {
      return this.find(function(desc){ return desc.get('name') === name; });
    }
  }, {
    /**
     * Build descriptors from JSON.
     * 
     * @param {Object|Array} data
     */
    fromJSON: function(data) {
      if(!Array.isArray(data)) 
        return this.fromJSON([data]);

      // New descriptor collection with `Element` base descriptor.
      var collection = new Elements.DescriptorCollection({ 
        name: 'Element',
        properties: new Elements.PropertyCollection()
      });

      var byName = { Element: collection.first() };

      for(var i = 0; i < data.length; i++) {
        var d = data[i],
            properties = new Elements.PropertyCollection(d.properties || []),
            descriptor = new Elements.Descriptor(d);

        descriptor.id = 'descriptor-' + descriptor.get('name');

        properties.each(function(prop){ prop.set({ descriptor: descriptor }); });

        descriptor.set({ properties: properties });

        collection.add(descriptor);
        byName[descriptor.get('name')] = descriptor;
      }

      collection.each(function(desc) {
        if(desc.get('name') === 'Element') return;

        var parent = desc.has('parent') ? desc.get('parent').name : 'Element';
        if(byName[parent]) 
          desc.set({ 'parent': byName[parent] });
        else
          console.warn("Element: ", desc.get('name'), " parent `", parent, "` not found!");
      });
      
      // Copy properties from descriptor parent to descriptor
      byName = {};
      function addParentProperties(desc) {
        var parent = desc.get('parent');
        if(parent) {
          var properties = desc.get('properties');

          if(!byName[parent.get('name')]) 
            addParentProperties(parent);
          
          var parentProperties = parent.get('properties');

          properties.models = [].concat(parentProperties.models).concat(properties.models);
          byName[desc.get('name')] = desc;
        }
      }
      collection.each(function(desc){ addParentProperties(desc); }, this);

      return collection;
    }
  });

  /** 
   * Property model
   *
   * Attributes:
   * * name: Name of property
   * * title: Title of property
   * * description: Description of property
   * * typename: Name of element or essence
   * * enum: Newline separated list of posible values
   * * required: Boolean, true if property required
   * * pattern: Regex pattern to validate text properties
   * * minimum: Minimum value for Numeric properties and minimum length for text properties
   * * maximum: Maximum value for Numeric properties and maximum length for text properties
   * * default: Default value
   * * widget: Lowercase name of widget class
   * * essence: Boolean, true if property is an essence
   * * array: Boolean, true if property is an array
   * * items: List of objects containing informations about posible elements in arrays
   *
   * Attributes of items:
   * * typename: Name of posible element types
   * * position: Position of element (for tuples)
   *
   */
  Elements.Property = Backbone.Model.extend({

    /**
     * Is this property an array?
     *
     * @return {Boolean}
     */
    isArray: function() {
      /*
       * var items = this.get('items');
       * if(!items || !items.length)
       *   return false;
       * return true;
       */
      return this.get('typename') === 'Array';
    }

  }, { modelName: 'Property' });

  /** Property model collection */
  Elements.PropertyCollection = Backbone.Collection.extend({
    model: Elements.Property,

    /**
     * Find property by name.
     *
     * @param {String}
     * @return {RefineryElements.Property}
     */
    findByName: function(name) {
      return this.find(function(prop){ return prop.get('name') === name; });
    }
  });

  /** Image model */
  Elements.EssenceImage = Backbone.Model.extend({}, { modelName: 'EssenceImage' });

  /** Resource model */
  Elements.EssenceResource = Backbone.Model.extend({}, { modelName: 'EssenceResource' });

  /** Any-Type model */
  Elements.EssenceAny = Backbone.Model.extend({}, { modelName: 'EssenceAny' });

  /** Base class of all element models. */
  Elements.Element = Backbone.Model.extend({}, { 
    modelName: 'Element',

    /**
     * Generates element model classes from a `Descriptors` collection.
     *
     * @param {Descriptors} Descriptor collection
     * @return {Object} Object with element model classes by name
     */
    buildModelClassesFromDescriptors: function(descriptors) {
      var classes = {};

      // Generate element model class from descriptor
      function elementModelFromDescriptor(descriptor) {
        if(!descriptor)
          return Elements.Element;

        var name = descriptor.get('name'),
            element = null;

        // Return element model if already exist.
        if((element = classes[name])) 
          return element;

        var parent = elementModelFromDescriptor(descriptor.get('parent'));

        // Model defaults
        var defaults = {};
        descriptor.get('properties').each(function(property) {
          var defaultValue = property.get('default');
          if(defaultValue && defaultValue.length > 0)
            defaults[property.get('name')] = defaultValue;
        });

        // Extend parent model
        element = classes[name] = parent.extend({ 
          defaults: defaults
        }, {
          // element decriptor
          descriptor: descriptor,
          // set element descriptor name as modelName
          modelName: descriptor.get('name'),
          // elemnt parent class
          superclass: parent
        });

        // Generate fromJSON class function
        element.fromJSON = (function(element) {
          return function(attrs) {
            var instance = new element(attrs);

            element.descriptor.get('properties').each(function(property) {
              var name = property.get('name'),
                  elementAttributes = attrs[name], 
                  attributes = {};

              // Array
              if(property.isArray()) {
                var collection = new Elements.ElementCollection();

                if(Array.isArray(elementAttributes)) {
                  _.each(elementAttributes, function(attrs) {
                    var element = classes[attrs.typename];
                    if(element) collection.add(element.fromJSON(attrs));
                  });
                }
                attributes[name] = collection;
                instance.set(attributes);
              // Image
              } else if(elementAttributes && property.get('typename') === 'Image') {
                attributes[name] = new Elements.EssenceImage(elementAttributes);
                instance.set(attributes);
              // Resource
              } else if(elementAttributes && property.get('typename') === 'Resource') {
                attributes[name] = new Elements.EssenceResource(elementAttributes);
                instance.set(attributes);
              // Any-Type
              } else if(elementAttributes && property.get('typename') === 'Any') {
                attributes[name] = new Elements.EssenceAny(elementAttributes);
                instance.set(attributes);
              // Element
              } else if(elementAttributes && !property.get('essence')) {
                if(!classes[property.get('typename')])
                var childElement = new classes[property.get('typename')].fromJSON(elementAttributes);

                attributes[name] = childElement;
                instance.set(attributes);
              }
            });

            return instance;
          };
        })(element);
      }

      descriptors.each(function(descriptor){ elementModelFromDescriptor(descriptor); });

      return classes;
    }

  });

  /** Element model collection */
  Elements.ElementCollection = Backbone.Collection.extend({ 
    model: Elements.Element,

    findByLocale: function(locale) {
      return this.find(function(model) { return model.get('locale') === locale; });
    },

    locales: function() {
      var locales = this.select(function(model) { return model.get('locale'); });
      return _.uniq(locales);
    }
  }, {

    fromJSON: function(list) {
      if(!Array.isArray(list))
         return this.fromJSON([list]);

      var collection = new Elements.ElementCollection();

      for(var i = 0; i < list.length; i++) {
        var data = list[i];
        var element = Elements.getElement(data.typename) || Elements.getElement('Element');

        collection.add(element.fromJSON(data));
      }
      return collection;
    }

  });

  /**
   * Elements editor
   *
   * Options:
   *
   * * el: Editor target
   * * currentModel: Current element model (optional)
   * * jsonData: Element models json data (optional)
   * * currentLocale: Current element locale (optional)
   * * currentDescriptor: Descriptor for current element (optional)
   * * baseName: Input base name (optional, default: 'elements')
   * * supportedLocales: Supported locales
   * * elementBase: Base class of choosable elments (optional, default: 'DocumentElement')
   * * headerOptions: Options for ElementsEditor.ElementsEditorHeaderView
   */
  var ElementsEditor = Elements.ElementsEditor = Backbone.Router.extend({

    routes: {
      "doctype/:type": "selectDocumentType",
      "locale/:locale": "selectDocumentLocale"
    },

    initialize: function(options) {
      this.currentLocale     = options.currentLocale || 'en';
      this.currentDescriptor = options.currentDescriptor;
      this.supportedLocales  = options.supportedLocales;

      var model = null;

      // we have a model
      if(options.model) {
        model = options.model;
      // we have json data
      } else if(options.jsonData) {
        this.models = Elements.ElementCollection.fromJSON(options.jsonData);
        // search for current locale
        if(this.currentLocale)
          model = this.models.findByLocale(this.currentLocale);
        // or use first model
        if(!model)
          model = this.models.first();
      // we have a descriptor
      } else if(this.currentDescriptor) {
        // resolve named descriptor
        if(typeof this.currentDescriptor === 'string')
          this.currentDescriptor = Elements.descriptors.findByName(this.currentDescriptor);

        // search element model class for descriptor
        var elementName = this.currentDescriptor.get('name'),
            element = Elements.getElement(elementName);

        // use element model class to build an empty model
        if(!element) throw new Error('Element model '+elementName+' doesn´t exist.');
        model = new element({ locale: this.currentLocale });
      }

      this.view = new ElementsEditor.ElementsEditorView({ 
        el: options.el, 
        baseName: options.baseName || 'elements',
        headerOptions: _.extend({
          supportedLocales: this.supportedLocales,
          elementBase: options.elementBase
        }, options.headerOptions || {})
      }).render();

      var self = this;

      $(this.view.header.documentTypeChooser).change(function(ev) {
        self.selectDocumentType($(ev.target).val());
      });

      $(this.view.header.localeChooser).change(function(ev) {
        self.selectDocumentLocale($(ev.target).val());
      });

      if(!this.models) this.models = new Elements.ElementCollection(model ? [model] : []);
      this.setCurrentModel(model);
    },

    getCurrentModel: function() {
      return this.currentModel;
    },

    setCurrentModel: function(model) {
      if(this.currentModel === model) return;

      this.currentModel = model;

      if(this.currentModel) {
        // get current descriptor
        this.currentDescriptor = model.constructor.descriptor;
        // set locale
        if(this.currentModel.has('locale'))
          this.currentLocale = this.currentModel.get('locale');
        else
          this.currentModel.set({ locale: this.currentLocale });

        var form = this.view.addElement(this.currentModel);
        this.view.showForm(form);

        this.view.header.setTitle('element :: ' + this.currentModel.constructor.modelName)
        this.view.header.setSelectedLocale(this.currentLocale);
        this.view.header.setSelectedDocumentType(this.currentDescriptor.get('name'));
      } else {
        this.view.header.setTitle('RefinerCMS :: Elements');
        this.view.header.setSelectedLocale(this.currentLocale);
        this.view.header.setSelectedDocumentType(null);

        this.view.hideAllForms();
      }
    },

    selectDocumentType: function(type) {
      if(this.currentModel && this.currentModel.constructor.modelName === type) return;

      if(this.currentModel) {
        var form = this.view.findFormForElement(this.currentModel)
        // if already persisted
        if(this.currentModel.get('id')) {
          // destroy 
          this.currentModel.set({ _destroy: true });
          // hide form if it exists
          if(form) $(form.el).hide();
        } else {
          // remove form if it exists
          if(form) form.remove();
        }
        // remove current model from collection
        this.models.remove(this.currentModel);
      }
      // get model class
      var elementClass = Elements.getElement(type);
      if(!elementClass) {
        this.setCurrentModel(null);
        return false;
      }

      // build model and add it to collection
      var model = new elementClass({ locale: this.currentLocale });
      this.models.add(model);

      this.setCurrentModel(model);

      return false;
    },

    selectDocumentLocale: function(locale) {
      if(this.currentLocale === locale) return;

      this.currentLocale = locale;

      var element = this.models.findByLocale(locale);

      if(element) {
        this.setCurrentModel(element);
        return false;
      }
      // else
      if(!this.currentDescriptor) return;
      // else
      var elementClass = Elements.getElement(this.currentDescriptor.get('name')),
          model = new elementClass({ locale: this.currentLocale });

      this.models.add(model);
      this.setCurrentModel(model);
      return false;
    }

  }, {
    widgets: w,

    helper: h,

    templates: t,

    defaultWidgets: {
      Element: 'ElementView',
      Text: 'EssenceTextView',
      Integer: 'EssenceNumberView',
      Float: 'EssenceNumberView',
      Image: 'EssenceImageView',
      Boolean: 'EssenceBooleanView',
      Resource: 'EssenceResourceView',
      Array: 'ListView'
    },

    /**
     * Get widget for element or property.
     *
     * @param Element|Property 
     * @return ElementsEditor.View
     */
    getWidget: function(element_or_property) {
      if(element_or_property instanceof Elements.Property)
        return this._getDefaultWidgetForProperty(element_or_property);
      else if(element_or_property instanceof Elements.Element)
        return this._getDefaultWidgetForElement(element_or_property);
    },

    // Get default widget by property
    _getDefaultWidgetForProperty: function(property) {
      var widget = this.widgets[property.get('widget')];

      if(widget) return widget;

      var typename = property.get('typename');

      // if property is essence
      if(property.get('essence') || property.isArray()) {
         var widgetName = ElementsEditor.defaultWidgets[typename];
         return ElementsEditor.widgets[widgetName];
      }
      // else if property is element
      var elementClass = Elements.getElement(typename);
      return this._getDefaultWidgetForElementClass(elementClass);
    },

    // Get default widget by element model
    _getDefaultWidgetForElement: function(element) {
      return this._getDefaultWidgetForElementClass(element.constructor);
    },

    // Get default widget by element model class
    _getDefaultWidgetForElementClass: function(element) {
      var base = element;
      while(base) {
        var widgetName  = ElementsEditor.defaultWidgets[base.modelName],
            widgetClass = w[widgetName];

        if(widgetClass) return widgetClass;

        if(base.__super__ && base.__super__.constructor)
          base = base.__super__.constructor;
        else
          return null;
      }
      return null;
    }
  });

  /**
   * Base class of all Elements views
   */
  Elements.View = Backbone.View.extend({

    initialize: function() {
      this.parent   = this.options.parent;
      this.children = [];
      if(this.parent) this.parent.registerChildWidget(this);
    },

    registerChildWidget: function(widget) {
      var index = _.indexOf(this.children, widget);
      if(index === -1) {
        this.children.push(widget);
        widget.bind('view:childWidgetRegistered', this.triggerChildWidgetRegistered, this);
        widget.bind('view:childWidgetUnregistered', this.triggerChildWidgetUnregistered, this);
        this.triggerChildWidgetRegistered(widget);
      }
    },

    triggerChildWidgetRegistered: function(widget) {
      this.trigger('view:childWidgetRegistered', widget);
    },

    triggerChildWidgetUnregistered: function(widget) {
      this.trigger('view:childWidgetUnregistered', widget);
    },

    unregisterChildWidget: function(widget) {
      var index = _.indexOf(this.children, this);
      if(index > -1) {
        var widget = this.children[index];
        this.children.splice(index, 1);
        widget.unbind('view:childWidgetRegistered', this.triggerChildWidgetRegistered);
        widget.unbind('view:childWidgetUnregistered', this.triggerChildWidgetUnregistered);
        this.triggerChildWidgetUnregistered(widget);
        return widget;
      }
    },

    remove: function() {
      Backbone.View.prototype.remove.apply(this, arguments);
      if(this.parent) this.parent.unregisterChildWidget(this);
    },

    getRoot: function() {
      if(!this.parent) return this;

      var root = this;
      while((root = root.parent))
        if(!root.parent) return root;
    },


  });

  /**
   * ElementsEditorView
   *
   * Options:
   * * baseName: Base name of form inputs
   * * headerOptions: Options for ElementsEditor.ElementsEditorHeaderView
   */
  ElementsEditor.ElementsEditorView = Elements.View.extend({
    className: 'elements-editor',

    initialize: function() {
      Elements.View.prototype.initialize.apply(this, arguments);
    },

    getInputName: function() {
      return this.options.baseName;
    },

    render: function() {
      Elements.View.prototype.render.apply(this, arguments);
    
      this.header = new ElementsEditor.ElementsEditorHeaderView(this.options.headerOptions).render();

      $(this.el).append(this.header.el).addClass(this.className);
      return this;
    },

    /**
     * Build ElementsEditorFormView for element.
     *
     * @param {Elements.Element} element
     * @return {ElementsEditor.ElementsEditorFormView}
     */
    buildFormForElement: function(element) {
      var formOptions = {
        parent: this,
        model: element,
      };
      return new ElementsEditor.ElementsEditorFormView(formOptions);
    },

    /**
     * Find form for element.
     *
     * @param {Elements.Element}
     * @return {ElementsEditor.ElementsEditorFormView}
     */
    findFormForElement: function(element) {
      return _.find(this.children, function(c) { 
        return (c instanceof ElementsEditor.ElementsEditorFormView && c.model.cid === element.cid); 
      });
    },

    showForm: function(form) {
      _.each(this.children, function(c) {
        if(c instanceof ElementsEditor.ElementsEditorFormView) {
          if(c === form) $(c.el).show();
          else $(c.el).hide();
        }
      }, this);
    },

    hideAllForms: function() {
      _.each(this.children, function(c) {
        if(c instanceof ElementsEditor.ElementsEditorFormView) {
          $(c.el).hide();
        }
      }, this);
    },

    /**
     * Add element editor view to widget body.
     *
     * @param {Elements.Element}
     * @return {ElementsEditor.ElementsEditorFormView}
     */
    addElement: function(element) {
      var form;
      // return form if already exist
      if((form = this.findFormForElement(element)))
        return form;

      // build new form view for element
      form = this.buildFormForElement(element);

      // add new form
      $(this.el).append(form.render().el);
      this.showForm(form);

      // emit DOMNodeInserted event
      form.trigger('view:DOMNodeInserted');
       
      return form;
    }

  });

  /**
   * ElementsEditorHeaderView
   *
   * Options:
   * * supportedLocales: Supported locales
   * * elementBase: Base class of choosable elements (optional, default: 'DocumentElement')
   */
  ElementsEditor.ElementsEditorHeaderView = Elements.View.extend({
    tagName: 'header',

    className: 'elements-editor-header',

    initialize: function() {
      this.supportedLocales = this.options.supportedLocales;

      var baseDescriptor = this.options.elementBase || 'DocumentElement'
      if(typeof baseDescriptor === 'string')
        this.baseDescriptor = Elements.descriptors.findByName(baseDescriptor);
      else
        this.baseDescriptor = baseDescriptor;
    },

    render: function() {
      this.title   = this.make('h1', { 'class': 'elements-editor-title' });
      this.toolbar = this.make('ul', { 'class': 'toolbar' });

      this.renderDocumentTypeChooser();
      this.renderLocalChooser();

      $(this.el).append(this.title).append(this.toolbar); 
      
      return this;
    },

    // render document type selectbox
    renderDocumentTypeChooser: function() {
      // Choosable document types
      var descriptors = _.sortBy(this.baseDescriptor.descendants(), function(desc) {
        return desc.get('name');
      });

      var documentTypeId = this.cid + '-document-type';
      this.documentTypeLabel = this.make('label', { for: documentTypeId }, I18n.t('js.admin.elements.editor.type'));
      this.documentTypeChooser = this.make('select', { id: documentTypeId }, this.make('option'));
      this.documentTypeAction = this.make('li', { 'class': 'action' });
      $(this.documentTypeAction).append(this.documentTypeLabel).append(this.documentTypeChooser);

      var documentItems = _.each(descriptors, function(desc) {
        var name = desc.get('name');
        $(this.documentTypeChooser).append(this.make('option', { value: name }, name));
      }, this);

      $(this.toolbar).append(this.documentTypeAction)
      $(this.documentTypeChooser).sb({ selectboxClass: 'selectbox documentChooser' });
    },

    // render document locale selectbox
    renderLocalChooser: function() {
      if(this.supportedLocales && this.supportedLocales.length > 1) {
        var localeChooserId = this.cid + '-document-locale';
        this.localeChooserLabel = this.make('label', { for: localeChooserId }, I18n.t('js.admin.elements.editor.locale'));
        this.localeChooser = this.make('select', { id: localeChooserId, class: 'localeChooser' });
        this.localeChooserAction = this.make('li', { 'class': 'action' });

        $(this.localeChooserAction).append(this.localeChooserLabel).append(this.localeChooser);
        $(this.localeChooserLabel).hide();

        var localeItems = _.each(this.supportedLocales, function(locale) {
          $(this.localeChooser).append(this.make('option', { value: locale }, locale));
        }, this);

        $(this.toolbar).append(this.localeChooserAction);

        var self = this;
        var localeFormater = function() {
          var locale = $(this).val();
          return self.make('img', { src: '/images/refinery/icons/flags/' + locale + '.png', alt: locale });
        };

        $(this.localeChooser).sb({ 
          selectboxClass: 'selectbox localeChooser',
          optionFormat: localeFormater,
          displayFormat: localeFormater
        });
      }
    },

    setTitle: function(title) {
      $(this.title).html(title);
    },

    setSelectedLocale: function(locale) {
      $(this.localeChooser).val(locale).sb('refresh');
    },

    setSelectedDocumentType: function(type) {
      $(this.documentTypeChooser).val(type).sb('refresh');
    }

  });


  /**
   * Elements editor form view
   */
  ElementsEditor.ElementsEditorFormView = Elements.View.extend({

    className: 'elements-editor-form',
    
    initialize: function() {
      Elements.View.prototype.initialize.apply(this, arguments);

      this.descriptor = this.model.constructor.descriptor;
      this.locale = this.model.get('locale');

      this.model.bind('change:_destroy', function(model, value) {
        if(this.destroyInput) this.$(this.destroyInput).val(value);
      }, this);
    },

    getInputName: function() {
      return this.parent.getInputName() + '[' + this.cid + ']';
    },

    render: function() {

      this.idInput = this.make('input', { 
        type: 'hidden',
        name: this.getInputName() + '[id]',
        value: this.model.id
      });

      this.typeInput = this.make('input', { 
        type: 'hidden',
        name: this.getInputName() + '[type]',
        value: this.descriptor.get('name')
      });
      
      this.localeInput = this.make('input', {
        type: 'hidden',
        name: this.getInputName() + '[locale]',
        value: this.locale
      });

      this.destroyInput = this.make('input', {
        type: 'hidden',
        name: this.getInputName() + '[_destroy]',
        value: this.model.get('_destroy')
      });

      var widgetClass = ElementsEditor.getWidget(this.model);
      // use DynamicView if widget for this.model is the default ElementView
      if(widgetClass === ElementsEditor.ElementView)
        widgetClass = ElementsEditor.DynamicView;

      this.widget = new widgetClass({ 
        parent: this,
        model: this.model,
        descriptor: this.descriptor
      });

      $(this.el)
        .append(this.idInput)
        .append(this.typeInput)
        .append(this.localeInput)
        .append(this.destroyInput)
        .append(this.widget.render().el) 
        .addClass(this.className);

      return this;
    }

  });

  /**
   * Render list of widgets from element descriptor.
   *
   * Options:
   * * parent: Parent widget
   * * model: Element model
   * * descriptor: Element descriptor
   */
  ElementsEditor.DynamicView = Elements.View.extend({ 

    tagName: 'ol',

    className: 'properties',

    initialize: function() {
      Elements.View.prototype.initialize.apply(this, arguments);

      this.parent = this.options.parent;

      this.descriptor = this.options.descriptor;

      if(!this.model) {
        var elementName = this.descriptor.get('name'),
            element = Elements.getElement(elementName);
        if(!element) throw new Error('Element model '+elementName+' doesn´t exist.');
        this.model = new element();
      }

      this.except = this.options.except;
      if(typeof this.except === 'string') {
        this.except = [this.except];
      }

      this.only = this.options.only;
      if(typeof this.only === 'string') {
        this.only = [this.only];
      }

      this.parent.bind('view:DOMNodeInserted', function() { 
        this.trigger('view:DOMNodeInserted', this);
      }, this);
    },

    getInputName: function() {
      return this.options.baseName || this.parent.getInputName();
    },

    render: function() {
      // render all properties
      this.elements = [];
      this.elements.named = {};
      this.descriptor.get('properties').each(function(property) {
        var name = property.get('name');
        // except
        if(this.except && _.include(this.except, name)) return;
        if(this.only && !_.include(this.only, name)) return; 

        var widget;
        if((widget = ElementsEditor.getWidget(property))) {
          var options = { parent: this, property: property };

          // if essence
          if(property.get('essence')) {
            options.model = this.model;
          // else if element
          } else {
            var model = this.model.get(property.get('name'));
            if(model) {
              options.model = model;
            } else {
              if(property.isArray()) {
                options.model = new Elements.ElementCollection();
              } else {
                var element = Elements.getElement(property.get('typename'));
                if(!element) return;
                options.model = new element();
              }
            }
          }
          var child = new widget(options);
          // append to list
          this.elements.push(child);
          this.elements.named[name] = child;

          $(this.el).append(child.render().el);
          $(child.el).addClass('clearfix');
        }
      }, this);

      return this;
    },

    size: function() {
      return this.elements.length;
    }

  });
  
  /** 
   * Base view class of all editor widgets.
   *
   * Options:
   * * parent: Parent widget
   * * property: Property model instance (null on elements in arrays)
   * * model: Element model instance
   * * headerless: Boolean, render without header if true
   */
  ElementsEditor.View = Elements.View.extend({
    togglable: false,
    
    events: {
      'click span.toggle:first': 'toggle',
      'click a.toggle:first':    'toggle'
    },

    initialize: function() {
      Elements.View.prototype.initialize.apply(this, arguments);

      this.property   = this.options.property;
      this.model      = this.options.model;
      this.opened     = true;
      this.headerless = this.options.headerless;

      $(this.el).attr('id', (this.id || (this.id = this.cid)));
    },

    getInputName: function() {
      return this.parent.getInputName() + '[' + this.property.get('name') + ']';
    },

    toggle: function() {
      if(!this.togglable) return false;

      this.opened = !this.opened;
      this.trigger('view:toggle', this);
      return false;
    }

  });

  /** Base view of all essence widgets. */
  t.essenceBaseTmpl =  
    "{{^headerless}}"                                         +
    "  <label for='{{inputId}}'>"                             +
    "    {{#isTogglable}}"                                    +
    "      <span class='toggle arrow'></span>"                +
    "      <span class='title'>{{title}}</span>"              +
    "      {{#isRequired}}<sup>*</sup>{{/isRequired}}"        +
    "    {{/isTogglable}}"                                    +
    "    {{^isTogglable}}"                                    +
    "      {{title}}"                                         +
    "      {{#isRequired}}<sup>*</sup>{{/isRequired}}"        +
    "    {{/isTogglable}}"                                    +
    "    {{#hasDescription}}"                                 +
    "      <span class='inline-hints'>{{description}}</span>" +
    "    {{/hasDescription}}"                                 +
    "  </label>"                                              +
    "{{/headerless}}"                                         +
    "{{>yield}}";
  ElementsEditor.EssenceView = ElementsEditor.View.extend({
    tagName: 'li',

    className: 'property field',

    template: h.mustacheTemplate(t.essenceBaseTmpl),

    yield: '',

    initialize: function() {
      ElementsEditor.View.prototype.initialize.apply(this, arguments);

      this.id = this.cid + '_essence';
      this.propertyName = this.property.get('name');

      this.bind('view:toggle', function() {
        if(this.togglable)
          $(this.el).toggleClass('closed');
      }, this);
    },

    getView: function() {
      var title = this.property.get('title'),
          desc  = this.property.get('description');

      return {
        name: this.getInputName(),
        title: title || this.propertyName,
        headerless: this.headerless,
        hasDescription: (desc && desc.length),
        description: desc,
        isTogglable: this.togglable,
        isRequired: this.property.get('required'),
        value: this.getValue(),
        inputId: this.getInputId()
      };
    },

    getInputId: function() {
      return this.id + '-' + this.propertyName;
    },

    getValue: function() {
      return this.model.get(this.propertyName);
    },

    setValue: function(value) {
      var attributes = {};
      attributes[this.propertyName] = value;
      return this.model.set(attributes);
    },

    render: function() {
      var el = $(this.el);
      el.html( this.template(this.getView(), { yield: this.yield }) );

      if(!this.headerless && this.property.get('required'))
        el.addClass('required');

      return this;
    }

  });

  /** 
   * Base view of all element views
   *
   * Options:
   * * sortable: Set to true if element is sortable
   * * deletable: Set to true if element is deletable
   *
   * Events:
   * * view:delete
   */
  t.elementBaseTmpl = 
    "{{^headerless}}"                                                                                    +
    "<div class='element-header'>"                                                                       +
    "  <span class='toggle arrow'></span>"                                                               +
    "  <span class='title'>{{title}}</span>"                                                             +
    "  {{#deletable}}"                                                                                   +
    "    <a class='delete' href='#'>"                                                                    +
    "      <img width='16' height='16' src='/images/refinery/icons/delete.png' alt='Delete'>"            +
    "    </a>"                                                                                           +
    "  {{/deletable}}"                                                                                   +
    "</div>"                                                                                             +
    "{{/headerless}}"                                                                                    +
    "<div class='element-body clearfix'>"                                                                +
    "  {{>yield}}"                                                                                       +
    "  {{^collection}}"                                                                                  +
    "    <input class='id' type='hidden' name='{{inputName}}[id]' value='{{elementId}}' />"              +
    "    <input class='type' type='hidden' name='{{inputName}}[type]' value='{{modelName}}' />"          +
    "    {{#sortable}}"                                                                                  +
    "      <input class='position' type='hidden' name='{{inputName}}[position]' value='{{position}}' />" +
    "    {{/sortable}}"                                                                                  +
    "    {{#deletable}}"                                                                                 +
    "      <input class='destroy' type='hidden' name='{{inputName}}[_destroy]' value='' />"              +
    "    {{/deletable}}"                                                                                 +
    "  {{/collection}}"                                                                                  +
    "</div>";

  ElementsEditor.ElementBaseView = ElementsEditor.View.extend({
    defaultDescriptor: '',

    tagName: 'li',

    className: 'element',

    template: h.mustacheTemplate( t.elementBaseTmpl ),

    yield: '',

    togglable: true,

    positionSelector: 'input[type=hidden].position:first',

    destroySelector: 'input[type=hidden].destroy:first',

    events: h.inheritEvents(ElementsEditor.View, {
      "click .element-header a.delete": "delete"
    }),

    initialize: function() {
      ElementsEditor.View.prototype.initialize.apply(this, arguments);

      this.sortable = this.options.sortable;
      
      this.deletable = this.options.deletable;

      if(this.options.descriptor)
        this.descriptor = this.options.descriptor;
      else if(this.model)
        this.descriptor = this.model.constructor.descriptor;
      else
        this.descriptor = Elements.descriptors.findByName(this.defaultDescriptor);

      this.parent.bind('view:DOMNodeInserted', function() {
        this.trigger('view:DOMNodeInserted');
      }, this);

      
      this.bind('view:toggle', function() {
        el.find('.element-header:first').toggleClass('closed');
        el.find('.element-body:first').slideToggle();
      }, this);

      if(this.sortable) {
        this.model.bind('change:position', function(model, value) {
          this.$(this.positionSelector).val(value);
        }, this);
      }

      if(this.deletable) {
        this.model.bind('change:_destroy', function(model, value) {
          this.$(this.destroySelector).val(value);
        }, this);
      }

    }, 

    getWidgetForProperty: function(name, options) {
      if(!this.widgets) this.widgets = {};

      var widget;
      if((widget = this.widgets[name])) return widget;

      var property = this.descriptor.get('properties').findByName(name);
      widget = ElementsEditor.getWidget(property);

      if(widget) {
        var widgetOptions = { 
          tagName: 'div', 
          parent: this, 
          property: property, 
          model: this.model 
        }
        if(options) { _.extend(widgetOptions, options); }
        var instance = new widget(widgetOptions);
        this.widgets[name] = instance;
        return instance;
      }
    },
    
    getInputName: function() {
      return this.parent.getInputName() + 
        (this.property ? '[' + this.property.get('name') + '_attributes]' : '') +
        (!this.property ? '[' + this.cid.replace('view', '') + ']' : '');
    },

    getView: function() {
      var title = '';
      if(this.property)
        title = (this.property.get('title') || this.property.get('name')) + ' :: ';
      title = title + this.elementTitle;

      var view = {
        elementId: this.model.get('id'),
        title:  title,
        sortable: this.sortable,
        deletable: this.deletable,
        headerless: this.headerless,
        modelName: this.model.constructor.modelName,
        inputName: this.getInputName(),
        collection: this.collection
      };
      if(this.sortable) {
        view.position = this.model.get('position') || 0;
        view.inputName = this.getInputName();
      }
      return view;
    },

    render: function() {
      var el = $(this.el);

      if(this.property) // if not an array
        el.addClass('property');

      el.html(this.template(this.getView(), {yield: this.yield }));

      return this;
    },

    delete: function() {
      if(this.deletable) {
        this.model.set({ _destroy: true });
        this.trigger('view:delete', this);
      }
      return false;
    },

    body: function(selector) {
      var body = this.$('.element-body:first');
      return selector ? body.find(selector) : body;
    },

    header: function(selector) {
      var header = this.$('.element-header:first');
      return selector ? header.find(selector) : header;
    },

  });

  ElementsEditor.ElementView = w.ElementView = ElementsEditor.ElementBaseView.extend({
    className: 'element elementView',
    
    yield: '',

    initialize: function() {
      ElementsEditor.ElementBaseView.prototype.initialize.apply(this, arguments);
      this.elementTitle = this.model.constructor.modelName;
    },

    render: function() {
      ElementsEditor.ElementBaseView.prototype.render.apply(this, arguments);

      this.dynamicView = new ElementsEditor.DynamicView({ 
        parent: this,
        model: this.model,
        descriptor: this.descriptor,
        only: this.options.only,
        except: this.options.except
      });

      this.body().append(this.dynamicView.render().el);

      return this;
    }
  });

  Elements.ImageCropperDialog = Backbone.View.extend({

    integerRegex: /^\s*\d+\s*$/,

    initialize: function() {
      this.width = this.options.width;
      this.trueWidth = this.options.trueWidth;
      this.height = this.options.height;
      this.trueHeight = this.options.trueHeight;
      this.ratio = this.width / this.height;
    },

    render: function() {
      $('.imageCropper').dialog('close').remove();

      // append el to document
      $('body').append(this.el);

      // open dialog
      $(this.el).dialog({
        modal: true,
        width: 'auto',
        height: 'auto',
        resizable: true,
      });

      var self = this;
      // close dialog
      this.$('.closeDialog').click(function() {
        self.remove();
        return false;
      });
      
      if(!$.browser.msie) { $(this.el).dialog('widget').corner('8px'); }

      // initialize Jcrop after image loaded
      this.$('img').bind('load', function() {

        var callback = function(ev) { self.setSelected(ev); };

        self.jcropApi = $.Jcrop(self.$('img'), {
          aspectRatio: 0,
          onChange: callback,
          onSelect: callback,
          trueSize: [self.trueWidth, self.trueHeight]
        });

        // enable/disable aspectRatio
        self.$('.ar_lock').change(function(ev) {
          self.jcropApi.setOptions(this.checked ? { aspectRatio: self.ratio } : { aspectRatio: 0 });
          self.jcropApi.focus(); 
        }).attr('checked', false);

        self.$('form').submit(function() {
          if(!self.selected) return false;

          var form   = $(this),
              method = form.attr('method'),
              url    = form.attr('action'),
              params = form.serialize() + '&' + $.param(self.selected);

          $.ajax({
            url: url, 
            method: method,
            data: params,
            dataType: 'json',
            success: function(data) { self.trigger('view:imageCropped', self, data); }
          });
          return false;
        });
      });

      this.height = this.$('.height').first();
      this.width = this.$('.width').first();

      $(this.height).change(function(ev) { 
        var val = $(this).val();
        if(self.integerRegex.test(val)) {
          self.setHeight(Number(val));
        } else {
          var s = self.jcropApi.tellSelect()
          $(this).val(s.h || '');
        }
      });

      $(this.width).change(function(ev) { 
        var val = $(this).val();
        if(self.integerRegex.test(val)) {
          self.setWidth(Number(val));
        } else {
          var s = self.jcropApi.tellSelect()
          $(this).val(s.w || '');
        }
      });

      return this;
    },

    remove: function() {
      $(this.el).dialog('close');
      Backbone.View.prototype.remove.apply(this, arguments);
    },

    setSelected: function(ev) {
      $(this.width).val(ev.w);
      $(this.height).val(ev.h);
      this.selected = ev;
    },

    setWidth: function(width) {
      var s = this.jcropApi.tellSelect();
      this.jcropApi.setSelect([s.x || 0, s.y || 0, (s.x + width), s.y2 || 1]);
    },

    setHeight: function(height) {
      var s = this.jcropApi.tellSelect();
      this.jcropApi.setSelect([s.x || 0, s.y || 0, s.x2 || 1, (s.y + height)]);
    }

  });

});
