Elements.ElementsEditor.widgets.PictureWidget = Elements.ElementsEditor.ElementBaseWidget.extend({
  defaultDescriptor: 'Picture',

  elementTitle: 'Picture',

  className: 'element pictureWidget clearfix',

  captionInputSelector: 'input[type=hidden].caption:first',

  captionSpanSelector: 'span.caption:first',

  yield: 
    "<span class='caption'></span>" +
    "<input class='caption' type='hidden' name='{{inputName}}[caption]' value='{{caption}}' />",

  getView: function(){
    var view = Elements.ElementsEditor.ElementBaseWidget.prototype.getView.apply(this, arguments);
    view.caption = this.model.get('caption');
    return view;
  },

  render: function() {
    Elements.ElementsEditor.ElementBaseWidget.prototype.render.apply(this, arguments);

    var caption     = this.body(this.captionInputSelector),
        captionSpan = this.body(this.captionSpanSelector),
        tooltip     = I18n.t('js.admin.elements.picture_view.click_to_edit');

    this.image = this.getWidgetForProperty('image', { headerless: true }).render();

    // re-trigger view:delete event from image
    this.image.bind('view:delete', function() { this.trigger('view:delete', this); }, this);

    this.body().prepend(this.image.el);

    // jeditable ...
    captionSpan.editable(function(value, settings) { 
      caption.val(value);
      return value;
    }, {
      width: 102,
      height: 16,
      cancel: I18n.t('js.admin.elements.picture_view.cancel'),
      submit: I18n.t('js.admin.elements.picture_view.submit'),
      tooltip: tooltip
    });

    var captionVal = caption.val();
    if(captionVal && captionVal.length > 0)
      captionSpan.text(captionVal);
    if(!this.image.hasImage)
      captionSpan.hide();

    this.image.bind('imageWidget:imageSelected', function(widget){
      captionSpan.show();
    }, this);

    this.image.bind('imageWidget:imageRemoved', function(widget){
      captionSpan.hide().text(tooltip);
      caption.val('');
    }, this);

    return this;
  }
   
});

Elements.ElementsEditor.defaultWidgets['Picture'] = 'PictureWidget';

/* vim: set filetype=javascript: */
