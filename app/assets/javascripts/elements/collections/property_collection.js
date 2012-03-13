/** Property model collection */
Elements.PropertyCollection = Backbone.Collection.extend({
  model: Elements.Property,

  /**
   * Find property by name.
   *
   * @param {String}
   * @return {RefineryElements.Property}
   */
  findByName: function(name) {
    return this.find(function(prop){ return prop.get('name') === name; });
  }
});
