/** Color view for text essences. */
Elements.ElementsEditor.widgets.EssenceColorWidget = Elements.ElementsEditor.EssenceWidget.extend({
  yield: '',

  events: {
    "click .color": "openPicker",
    "mouseleave .colorPicker": "closePicker"
  },

  initialize: function(){
    Elements.ElementsEditor.EssenceWidget.prototype.initialize.apply(this, arguments);

    this.opened = false;
  },

  render: function(){
    Elements.ElementsEditor.EssenceWidget.prototype.render.apply(this, arguments);

    var enumeration = this.property.get('enum');
    if(enumeration && enumeration.length) {
      this.selectbox = this.make('select');

      var self = this;
      _.each(enumeration, function(c) {
        $(self.selectbox).append(self.make('option', { value: c }, c));
      });

      $(this.el).append(this.selectbox);
      var colorFormater = function() {
        var span = self.make('span', { 'class': 'colorOption' }),
            value = $(this).val(),
            color = self.make('span', {
              'class': 'color',
              style: 'background-color:' + value + ';'
            }),
            title = self.make('span', { 'class':'title' }, value);
        $(span).append(color).append(title);
        return span;
      };

      $(this.selectbox).sb({
        optionFormat: colorFormater,
        displayFormat: colorFormater
      });
    } else {
      this.input = this.make('input', {
        id: this.getInputId(),
        name: this.getInputName(),
        'class': 'color',
        type: 'text',
        value: this.getValue() || '#ffffff',
        size: 7
      });
      this.colorPicker = this.make('div', { 'class': 'colorPicker' });

      $(this.el).append(this.input).append(this.colorPicker);
      $(this.colorPicker).farbtastic(this.input).hide();
    }
    return this;
  },

  openPicker: function() {
    if(!this.opened) {
      this.$('.colorPicker').fadeIn('fast');
      this.opened = true;
    }
    return false;
  },

  closePicker: function() {
    if(this.opened) {
      this.$('.colorPicker').fadeOut('fast');
      this.opened = false;
    }
    return false;
  }
});

/* vim: set filetype=javascript: */
