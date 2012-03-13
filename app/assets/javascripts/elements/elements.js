I18n = {};
I18n.t = function() { return '- no i18n-js installed' };

window.Elements = {
  /**
   * Generates element descriptors from JSON data
   */
  init: function(data) {
    this.descriptors = Elements.DescriptorCollection.fromJSON(data);
    this.elements = Elements.Element.buildModelClassesFromDescriptors(this.descriptors);
  },

  getElement: function(name) {
    return this.elements[name];
  },

  helper: {}
};
