Elements.ElementsEditor.widgets.GalleryWidget = Elements.ElementsEditor.ElementBaseWidget.extend({
  elementTitle: 'Gallery',

  className: 'element galleryWidget clearfix',

  render: function() {
    Elements.ElementsEditor.ElementBaseWidget.prototype.render.apply(this, arguments);

    var collection = this.model.get('pictures');

    if(!collection) {
      collection = new Elements.ElementCollection();
      this.model.set({ images: collection });
    }

    this.pictureList = this.getWidgetForProperty('pictures', {
      model: collection,
      togglable: false,
      headerless: true
    });

    this.body().append(this.pictureList.render().el);

    return this;
  }

});

Elements.ElementsEditor.defaultWidgets['Gallery'] = 'GalleryWidget';

/* vim: set filetype=javascript: */
