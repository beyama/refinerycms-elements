/** 
 * Descriptor model 
 * 
 * Attributes:
 * * name: Name of descriptor
 * * title: Title of descriptor
 * * description: Description of descriptor
 * * parent: Object with `name` attribute holding the name of parent descriptor
 * * properties: Properties collection
 */
Elements.Descriptor = Backbone.Model.extend({
  /**
   * Find all descendants of `this` descriptor.
   *
   * @return {Array}
   */
  descendants: function() {
    var children = [],
        baseName = this.get('name');

    this.collection.each(function(desc) { 
      var parent = desc.get('parent');
      if(parent && parent.get('name') === baseName) {
        children.push(desc);
        var descendants = desc.descendants();
        if(descendants.length)
          children = children.concat(descendants);
      }
    });
    return children;
  }
}, { modelName: 'Descriptor' });
