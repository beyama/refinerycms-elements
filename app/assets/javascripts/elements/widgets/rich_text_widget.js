Elements.ElementsEditor.widgets.RichTextWidget = Elements.ElementsEditor.ElementBaseWidget.extend({
  elementTitle: 'Rich Text',

  className: 'element richTextWidget clearfix',

  initialize: function() {
    Elements.ElementsEditor.ElementBaseWidget.prototype.initialize.apply(this, arguments);
  },

  render: function() {
    Elements.ElementsEditor.ElementBaseWidget.prototype.render.apply(this, arguments);

    this.richTextWidget = this.getWidgetForProperty('text', {
      togglable: false,
      headerless: true
    });

    // this.bind('view:DOMNodeInserted', this.fixEditorSize, this);
    this.body().append(this.richTextWidget.render().el);

    return this;
  }
});

Elements.ElementsEditor.defaultWidgets['RichText'] = 'RichTextWidget';

/* vim: set filetype=javascript: */
