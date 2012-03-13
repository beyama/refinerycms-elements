Elements.ImageCropperDialog = Backbone.View.extend({

  integerRegex: /^\s*\d+\s*$/,

  initialize: function() {
    this.width = this.options.width;
    this.trueWidth = this.options.trueWidth;
    this.height = this.options.height;
    this.trueHeight = this.options.trueHeight;
    this.ratio = this.width / this.height;
  },

  render: function() {
    $('.imageCropper').dialog('close').remove();

    // append el to document
    $('body').append(this.el);

    // open dialog
    $(this.el).dialog({
      modal: true,
      width: 'auto',
      height: 'auto',
      resizable: true,
    });

    var self = this;
    // close dialog
    this.$('.closeDialog').click(function() {
      self.remove();
      return false;
    });
    
    if(!$.browser.msie) { $(this.el).dialog('widget').corner('8px'); }

    // initialize Jcrop after image loaded
    this.$('img').bind('load', function() {

      var callback = function(ev) { self.setSelected(ev); };

      self.jcropApi = $.Jcrop(self.$('img'), {
        aspectRatio: 0,
        onChange: callback,
        onSelect: callback,
        trueSize: [self.trueWidth, self.trueHeight]
      });

      // enable/disable aspectRatio
      self.$('.ar_lock').change(function(ev) {
        self.jcropApi.setOptions(this.checked ? { aspectRatio: self.ratio } : { aspectRatio: 0 });
        self.jcropApi.focus(); 
      }).attr('checked', false);

      self.$('form').submit(function() {
        if(!self.selected) return false;

        var form   = $(this),
            method = form.attr('method'),
            url    = form.attr('action'),
            params = form.serialize() + '&' + $.param(self.selected);

        $.ajax({
          url: url, 
          method: method,
          data: params,
          dataType: 'json',
          success: function(data) { self.trigger('view:imageCropped', self, data); }
        });
        return false;
      });
    });

    this.height = this.$('.height').first();
    this.width = this.$('.width').first();

    $(this.height).change(function(ev) { 
      var val = $(this).val();
      if(self.integerRegex.test(val)) {
        self.setHeight(Number(val));
      } else {
        var s = self.jcropApi.tellSelect()
        $(this).val(s.h || '');
      }
    });

    $(this.width).change(function(ev) { 
      var val = $(this).val();
      if(self.integerRegex.test(val)) {
        self.setWidth(Number(val));
      } else {
        var s = self.jcropApi.tellSelect()
        $(this).val(s.w || '');
      }
    });

    return this;
  },

  remove: function() {
    $(this.el).dialog('close');
    Backbone.View.prototype.remove.apply(this, arguments);
  },

  setSelected: function(ev) {
    $(this.width).val(ev.w);
    $(this.height).val(ev.h);
    this.selected = ev;
  },

  setWidth: function(width) {
    var s = this.jcropApi.tellSelect();
    this.jcropApi.setSelect([s.x || 0, s.y || 0, (s.x + width), s.y2 || 1]);
  },

  setHeight: function(height) {
    var s = this.jcropApi.tellSelect();
    this.jcropApi.setSelect([s.x || 0, s.y || 0, s.x2 || 1, (s.y + height)]);
  }

});
