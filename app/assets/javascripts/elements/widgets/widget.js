/** 
 * Base view class of all editor widgets.
 *
 * Options:
 * * parent: Parent widget
 * * property: Property model instance (null on elements in arrays)
 * * model: Element model instance
 * * headerless: Boolean, render without header if true
 */
Elements.ElementsEditor.Widget = Elements.View.extend({
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
