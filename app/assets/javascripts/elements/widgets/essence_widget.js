/** Base view of all essence widgets. */
var essenceBaseTmpl =  
  "{{^headerless}}"                                         +
  "  <label for='{{inputId}}'>"                             +
  "    {{#isTogglable}}"                                    +
  "      <span class='toggle arrow'></span>"                +
  "      <span class='title'>{{title}}</span>"              +
  "      {{#isRequired}}<sup>*</sup>{{/isRequired}}"        +
  "    {{/isTogglable}}"                                    +
  "    {{^isTogglable}}"                                    +
  "      {{title}}"                                         +
  "      {{#isRequired}}<sup>*</sup>{{/isRequired}}"        +
  "    {{/isTogglable}}"                                    +
  "    {{#hasDescription}}"                                 +
  "      <span class='inline-hints'>{{description}}</span>" +
  "    {{/hasDescription}}"                                 +
  "  </label>"                                              +
  "{{/headerless}}"                                         +
  "{{>yield}}";
Elements.ElementsEditor.EssenceWidget = Elements.ElementsEditor.Widget.extend({
  tagName: 'li',

  className: 'property field',

  template: Elements.helper.mustacheTemplate(essenceBaseTmpl),

  yield: '',

  initialize: function() {
    Elements.ElementsEditor.Widget.prototype.initialize.apply(this, arguments);

    this.id = this.cid + '_essence';
    this.propertyName = this.property.get('name');

    this.bind('view:toggle', function() {
      if(this.togglable)
        $(this.el).toggleClass('closed');
    }, this);
  },

  getView: function() {
    var title = this.property.get('title'),
        desc  = this.property.get('description');

    return {
      name: this.getInputName(),
      title: title || this.propertyName,
      headerless: this.headerless,
      hasDescription: (desc && desc.length),
      description: desc,
      isTogglable: this.togglable,
      isRequired: this.property.get('required'),
      value: this.getValue(),
      inputId: this.getInputId()
    };
  },

  getInputId: function() {
    return this.id + '-' + this.propertyName;
  },

  getValue: function() {
    return this.model.get(this.propertyName);
  },

  setValue: function(value) {
    var attributes = {};
    attributes[this.propertyName] = value;
    return this.model.set(attributes);
  },

  render: function() {
    var el = $(this.el);
    el.html( this.template(this.getView(), { yield: this.yield }) );

    if(!this.headerless && this.property.get('required'))
      el.addClass('required');

    return this;
  }

});
