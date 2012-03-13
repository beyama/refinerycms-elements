Elements.ElementsEditor.widgets.PictureListWidget = Elements.ElementsEditor.widgets.ListWidget.extend({
  elementTitle: 'Picture list',

  className: 'element pictureListWidget clearfix',
  
  defaultChildWidgetOptions: {
    sortable: true,
    deletable: true,
    headerless: true
  },

  initialize: function() {
    Elements.ElementsEditor.widgets.ListWidget.prototype.initialize.apply(this, arguments) 

    this.newImage = new Elements.EssenceImage();

    // Callback function
    var self = this;
    window[this.cid + '_changed'] = function(image) {
      self.newImage.set(Elements.helper.extractDataFromImageDialog(image));
    }

    this.newImage.bind('change:id', function addNewImage(model, value) {
      // copy current image model
      var image = this.newImage;
      // unbind callback
      image.unbind('change:id', addNewImage);

      // replace current image model with new image model
      this.newImage = new Elements.EssenceImage();
      // bind callback to new image model
      this.newImage.bind('change:id', addNewImage, this);

      // create new picture class with image model
      var pictureClass = Elements.getElement('Picture');
      var picture = new pictureClass({ image: image, parent: this });

      // Open list widget if closed
      if(!this.opened) this.toggle();

      // add element to list
      var widget = this.addElement(picture);

      // Scroll to top of new widget
      Elements.helper.scrollToWidget(widget);
    }, this);

    this.parent.bind('view:DOMNodeInserted', function onNodeInserted() {
      this.parent.unbind('view:DOMNodeInserted', onNodeInserted);

      window.init_modal_dialogs();
    }, this);
  },

  renderToolbar: function() {
    var addLink = this.make('a', {
      'class': 'add_icon addPicture dialog',
      href: '/refinery/images/insert?callback=' + this.cid + '_changed' + '&width=866&height=510&dialog=true'
    }, I18n.t('js.admin.elements.picture_list_view.add'));

    if(this.headerless)
      $(this.el).prepend(addLink);
    else
      this.$('.element-header').append(addLink);
  }

});

/* vim: set filetype=javascript: */
