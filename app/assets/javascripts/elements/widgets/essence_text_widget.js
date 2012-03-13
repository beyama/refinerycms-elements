Elements.ElementsEditor.widgets.EssenceTextWidget = Elements.ElementsEditor.EssenceWidget.extend({

  initialize: function() {
    Elements.ElementsEditor.EssenceWidget.prototype.initialize.apply(this, arguments);
    
    this.minimum = this.property.get('minimum') || 0;
    this.maximum = this.property.get('maximum') || 0;

    if(this.isTextarea()) {
      this.togglable = true;

      this.bind('view:toggle', function() {
        this.$('textarea').slideToggle();
      }, this);
    }

  },

  isTextarea: function() {
    return ((this.minimum && this.minimum > 250) || 
            (this.maximum && this.maximum > 250) || 
            (!this.minimum && !this.maximum));
  },

  render: function() {
    Elements.ElementsEditor.EssenceWidget.prototype.render.apply(this, arguments);

    if(this.isTextarea()) {
      this.input = this.make('textarea', {
        id: this.getInputId(),
        name: this.getInputName(),
        cols: 20,
        rows: (this.maximum && this.maximum <= 1000) ? 3 : 10
      }, this.getValue());
    } else {
      this.input = this.make('input', {
        id: this.getInputId(),
        name: this.getInputName(),
        type: 'text',
        length: this.maximum ? this.maximum : 250,
        value: this.getValue()
      });
    }

    $(this.el).append(this.input);
    return this;
  }

});
/* vim: set filetype=javascript: */
