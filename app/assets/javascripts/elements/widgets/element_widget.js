Elements.ElementsEditor.widgets.ElementWidget = Elements.ElementsEditor.ElementBaseWidget.extend({
  className: 'element elementWidget',
  
  yield: '',

  initialize: function() {
    Elements.ElementsEditor.ElementBaseWidget.prototype.initialize.apply(this, arguments);
    this.elementTitle = this.model.constructor.modelName;
  },

  render: function() {
    Elements.ElementsEditor.ElementBaseWidget.prototype.render.apply(this, arguments);

    this.dynamicView = new Elements.ElementsEditor.DynamicView({ 
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
