/** Descriptor model collection */
Elements.DescriptorCollection = Backbone.Collection.extend({
  model: Elements.Descriptor,

  /**
   * Find descriptor by name.
   *
   * @param {String}
   * @return {RefineryElements.Descriptor}
   */
  findByName: function(name) {
    return this.find(function(desc){ return desc.get('name') === name; });
  }
}, {
  /**
   * Build descriptors from JSON.
   * 
   * @param {Object|Array} data
   */
  fromJSON: function(data) {
    if(!Array.isArray(data)) 
      return this.fromJSON([data]);

    // New descriptor collection with `Element` base descriptor.
    var collection = new Elements.DescriptorCollection({ 
      name: 'Element',
      properties: new Elements.PropertyCollection()
    });

    var byName = { Element: collection.first() };

    for(var i = 0; i < data.length; i++) {
      var d = data[i],
          properties = new Elements.PropertyCollection(d.properties || []),
          descriptor = new Elements.Descriptor(d);

      descriptor.id = 'descriptor-' + descriptor.get('name');

      properties.each(function(prop){ prop.set({ descriptor: descriptor }); });

      descriptor.set({ properties: properties });

      collection.add(descriptor);
      byName[descriptor.get('name')] = descriptor;
    }

    collection.each(function(desc) {
      if(desc.get('name') === 'Element') return;

      var parent = desc.has('parent') ? desc.get('parent').name : 'Element';
      if(byName[parent]) 
        desc.set({ 'parent': byName[parent] });
      else
        console.warn("Element: ", desc.get('name'), " parent `", parent, "` not found!");
    });
    
    // Copy properties from descriptor parent to descriptor
    byName = {};
    function addParentProperties(desc) {
      var parent = desc.get('parent');
      if(parent) {
        var properties = desc.get('properties');

        if(!byName[parent.get('name')]) 
          addParentProperties(parent);
        
        var parentProperties = parent.get('properties');

        properties.models = [].concat(parentProperties.models).concat(properties.models);
        byName[desc.get('name')] = desc;
      }
    }
    collection.each(function(desc){ addParentProperties(desc); }, this);

    return collection;
  }
});
