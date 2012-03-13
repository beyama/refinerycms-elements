/**
 * Elements editor form view
 */
Elements.ElementsEditor.ElementsEditorFormView = Elements.View.extend({

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

    var widgetClass = Elements.ElementsEditor.getWidget(this.model);
    // use DynamicView if widget for this.model is the default ElementWidget
    if(widgetClass === Elements.ElementsEditor.widgets.ElementWidget)
      widgetClass = Elements.ElementsEditor.DynamicView;

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
