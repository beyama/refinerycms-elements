/**
 * Renders a list of widgets from element descriptor.
 *
 * Options:
 * * parent: Parent widget
 * * model: Element model
 * * descriptor: Element descriptor
 */
Elements.ElementsEditor.DynamicView = Elements.View.extend({ 

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
      if((widget = Elements.ElementsEditor.getWidget(property))) {
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
