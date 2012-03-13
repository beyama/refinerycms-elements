/** 
 * Mustache template helper function.
 *
 * @param String Mustache template
 * @return Function
 */
Elements.helper.mustacheTemplate = function(template) {
  return function(view, partials) {
    return Mustache.to_html(template, view, partials);
  };
};

Elements.helper.inheritEvents = function(baseclass, events) {
  return function() {
    var self = this;
    function getEvents(events) {
      if(typeof events === 'function')
        return events.call(self);
      return events;
    };

    return _.extend({}, getEvents(baseclass.prototype.events), getEvents(events));
  };
};

Elements.helper.scrollToWidget = function(widget) {
  $('html,body').animate({ scrollTop: $(widget.el).offset().top }, 1000);
};

Elements.helper.extractDataFromImageDialog = function(image) {
  var image = $(image);

  return {
    id: image.attr('id').replace("image_", ""),
    thumbnail: image.attr('src'),
    thumbnail_large: image.data('large'),
    thumbnail_medium: image.data('medium'),
    thumbnail_small: image.data('small'),
    original: image.data('original'),
    image_name: image.attr('title')
  };
};
