/** Base class of all element models. */
Elements.Element = Backbone.Model.extend({}, { 
  modelName: 'Element',

  /**
   * Generates element model classes from a `Descriptors` collection.
   *
   * @param {Descriptors} Descriptor collection
   * @return {Object} Object with element model classes by name
   */
  buildModelClassesFromDescriptors: function(descriptors) {
    var classes = {};

    // Generate element model class from descriptor
    function elementModelFromDescriptor(descriptor) {
      if(!descriptor)
        return Elements.Element;

      var name = descriptor.get('name'),
          element = null;

      // Return element model if already exist.
      if((element = classes[name])) 
        return element;

      var parent = elementModelFromDescriptor(descriptor.get('parent'));

      // Model defaults
      var defaults = {};
      descriptor.get('properties').each(function(property) {
        var defaultValue = property.get('default');
        if(defaultValue && defaultValue.length > 0)
          defaults[property.get('name')] = defaultValue;
      });

      // Extend parent model
      element = classes[name] = parent.extend({ 
        defaults: defaults
      }, {
        // element decriptor
        descriptor: descriptor,
        // set element descriptor name as modelName
        modelName: descriptor.get('name'),
        // elemnt parent class
        superclass: parent
      });

      // Generate fromJSON class function
      element.fromJSON = (function(element) {
        return function(attrs) {
          var instance = new element(attrs);

          element.descriptor.get('properties').each(function(property) {
            var name = property.get('name'),
                elementAttributes = attrs[name], 
                attributes = {};

            // Array
            if(property.isArray()) {
              var collection = new Elements.ElementCollection();

              if(Array.isArray(elementAttributes)) {
                _.each(elementAttributes, function(attrs) {
                  var element = classes[attrs.typename];
                  if(element) collection.add(element.fromJSON(attrs));
                });
              }
              attributes[name] = collection;
              instance.set(attributes);
            // Image
            } else if(elementAttributes && property.get('typename') === 'Image') {
              attributes[name] = new Elements.EssenceImage(elementAttributes);
              instance.set(attributes);
            // Resource
            } else if(elementAttributes && property.get('typename') === 'Resource') {
              attributes[name] = new Elements.EssenceResource(elementAttributes);
              instance.set(attributes);
            // Any-Type
            } else if(elementAttributes && property.get('typename') === 'Any') {
              attributes[name] = new Elements.EssenceAny(elementAttributes);
              instance.set(attributes);
            // Element
            } else if(elementAttributes && !property.get('essence')) {
              if(!classes[property.get('typename')])
              var childElement = new classes[property.get('typename')].fromJSON(elementAttributes);

              attributes[name] = childElement;
              instance.set(attributes);
            }
          });

          return instance;
        };
      })(element);
    }

    descriptors.each(function(descriptor){ elementModelFromDescriptor(descriptor); });

    return classes;
  }

});
