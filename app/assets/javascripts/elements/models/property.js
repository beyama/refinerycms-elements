/** 
 * Property model
 *
 * Attributes:
 * * name: Name of property
 * * title: Title of property
 * * description: Description of property
 * * typename: Name of element or essence
 * * enum: Newline separated list of posible values
 * * required: Boolean, true if property required
 * * pattern: Regex pattern to validate text properties
 * * minimum: Minimum value for Numeric properties and minimum length for text properties
 * * maximum: Maximum value for Numeric properties and maximum length for text properties
 * * default: Default value
 * * widget: Lowercase name of widget class
 * * essence: Boolean, true if property is an essence
 * * array: Boolean, true if property is an array
 * * items: List of objects containing informations about posible elements in arrays
 *
 * Attributes of items:
 * * typename: Name of posible element types
 * * position: Position of element (for tuples)
 *
 */
Elements.Property = Backbone.Model.extend({

  /**
   * Is this property an array?
   *
   * @return {Boolean}
   */
  isArray: function() {
    /*
     * var items = this.get('items');
     * if(!items || !items.length)
     *   return false;
     * return true;
     */
    return this.get('typename') === 'Array';
  }

}, { modelName: 'Property' });
