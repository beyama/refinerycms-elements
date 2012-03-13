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
Elements.ElementsEditor = Backbone.Router.extend({

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

    this.view = new Elements.ElementsEditor.ElementsEditorView({ 
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
  widgets: {},

  defaultWidgets: {
    Element: 'ElementWidget',
    Text: 'EssenceTextWidget',
    Integer: 'EssenceNumberWidget',
    Float: 'EssenceNumberWidget',
    Image: 'EssenceImageWidget',
    Boolean: 'EssenceBooleanWidget',
    Resource: 'EssenceResourceWidget',
    Array: 'ListWidget'
  },

  /**
   * Get widget for element or property.
   *
   * @param Element|Property 
   * @return Elements.ElementsEditor.Widget
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
       var widgetName = Elements.ElementsEditor.defaultWidgets[typename];
       return this.widgets[widgetName];
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
      var widgetName  = Elements.ElementsEditor.defaultWidgets[base.modelName],
          widgetClass = Elements.ElementsEditor.widgets[widgetName];

      if(widgetClass) return widgetClass;

      if(base.__super__ && base.__super__.constructor)
        base = base.__super__.constructor;
      else
        return null;
    }
    return null;
  }
});
