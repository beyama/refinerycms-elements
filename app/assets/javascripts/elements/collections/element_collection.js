/** Element model collection */
Elements.ElementCollection = Backbone.Collection.extend({ 
  model: Elements.Element,

  findByLocale: function(locale) {
    return this.find(function(model) { return model.get('locale') === locale; });
  },

  locales: function() {
    var locales = this.select(function(model) { return model.get('locale'); });
    return _.uniq(locales);
  }
}, {

  fromJSON: function(list) {
    if(!Array.isArray(list))
       return this.fromJSON([list]);

    var collection = new Elements.ElementCollection();

    for(var i = 0; i < list.length; i++) {
      var data = list[i];
      var element = Elements.getElement(data.typename) || Elements.getElement('Element');

      collection.add(element.fromJSON(data));
    }
    return collection;
  }

});
