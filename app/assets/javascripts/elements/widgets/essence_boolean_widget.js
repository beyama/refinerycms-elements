Elements.ElementsEditor.widgets.EssenceBooleanWidget = Elements.ElementsEditor.EssenceWidget.extend({
  className: 'property field essenceBooleanWidget',

  yield: '',

  togglable: false,

  render: function() {
    Elements.ElementsEditor.EssenceWidget.prototype.render.apply(this, arguments);

    this.input = this.make('input', {
      id: this.getInputId(),
      name: this.getInputName(),
      type: 'checkbox',
      value: '1',
      checked: this.getValue()
    });

    $(this.el).append(this.input);

    return this;
  }

});

/* vim: set filetype=javascript: */
