/** List view */
Elements.ElementsEditor.widgets.ListWidget = Elements.ElementsEditor.ElementBaseWidget.extend({
  elementTitle: 'List',

  collection: true,

  className: 'element listWidget',

  yield: "<ul class='list items'></ul>",

  listSelector: '.list:first',

  defaultChildWidgetOptions: {
    sortable: true,
    deletable: true
  },

  initialize: function() {
    Elements.ElementsEditor.ElementBaseWidget.prototype.initialize.apply(this, arguments);
    this.collection = this.model;
    this.items = [];

    this.bind('view:DOMNodeInserted', function() { this.inserted = true; }, this);
  },

  render: function(){
    Elements.ElementsEditor.ElementBaseWidget.prototype.render.apply(this, arguments);

    var self = this;

    // Add element views
    this.collection.each(function(element) {
      this.addElement(element);
    }, this);

    // Make items sortable
    this.body(this.listSelector).sortable({ 
      // Update position
      update: function() { self.reorder(); },
      cursor: 'move',
      handle: '.element-header > .title'
    }); 

    this.renderToolbar();

    return this;
  },

  renderToolbar: function() {
    var baseDescriptor = Elements.descriptors.findByName('EmbeddedElement');
    var descriptors = _.sortBy(baseDescriptor.descendants(), function(desc) {
      return desc.get('name');
    });

    this.elementChooser = this.make('select');

    var self = this;
    _.each(descriptors, function(desc) {
      var name = desc.get('name'),
          option = self.make('option', { value: name }, name);
      $(self.elementChooser).append(option);
    });

    this.header().append(this.elementChooser); 

    $(this.elementChooser).change(function() {
      var type = $(this).val();
      if(!type.length) return;
      self.addElementByName(type);
      $(this).val('').sb('refresh');
    });

    $(this.elementChooser).sb({
      selectboxClass: 'selectbox elementChooser',
      fixedWidth: true,
      displayFormat: function() { return I18n.t('js.admin.elements.list_view.add_element'); }
    });
  },

  reorder: function() {
    var array = this.body(this.listSelector).sortable('toArray'),
        position = 0;

    for(var i = 0; i < array.length; i++) {
      var id = array[i],
          widget = _.find(this.items, function(item) { return item.id === id });

      if(widget) { 
        widget.model.set({ position: position });
        position++;
      }
    }
  },

  // Refresh sortable list
  refresh: function(){
    this.body(this.listSelector).sortable('refresh');
  },

  addElementByName: function(type) {
    var elementClass = Elements.getElement(type),
        element      = new elementClass({ position: this.items.length });

    // Add element to list
    var widget = this.addElement(element);

    // Open list widget if closed
    if(!this.opened) this.toggle();

    // Scroll to top of new widget
    Elements.helper.scrollToWidget(widget);
  },

  /**
   * Add element model to list and append widget view.
   *
   * @param {ElementsEditor.Element} Element model
   * @return {ElementsEditor.View} The append Widget 
   */
  addElement: function(element) {
    var widgetClass = Elements.ElementsEditor.getWidget(element);

    var widget = new widgetClass(_.extend({}, this.defaultChildWidgetOptions, {
      parent: this, 
      model: element,
    }));

    // Set position
    element.set({ position: this.items.length });

    // Add widget to items list
    this.items.push(widget);

    // Add element model to collection
    if(!this.collection.include(element))
      this.collection.add(element);

    // Append new widget to bottom of list
    this.body('ul.items:first').append(widget.render().el);

    // Trigger DOMNodeInserted on new widget
    if(this.inserted)
      widget.trigger('view:DOMNodeInserted');

    this.refresh();

    // Register delete handler
    widget.bind('view:delete', function(widget) {
      var index = _.indexOf(this.items, widget);
      if(index > -1) {
        var widget = this.items[index];
        this.items.splice(index, 1);
        this.collection.remove(widget.model);
        var self = this;
        $(widget.el).slideUp('fast', function() {
          if(!widget.model.get('id'))
            widget.remove();
          self.refresh();
          self.reorder();
        });
      }
      return false;
    }, this);

    return widget;
  }

});

/* vim: set filetype=javascript: */
