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
  }

});
