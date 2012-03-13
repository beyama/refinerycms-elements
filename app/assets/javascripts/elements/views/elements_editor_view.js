/**
 * ElementsEditorView
 *
 * Options:
 * * baseName: Base name of form inputs
 * * headerOptions: Options for ElementsEditor.ElementsEditorHeaderView
 */
Elements.ElementsEditor.ElementsEditorView = Elements.View.extend({
  className: 'elements-editor',

  initialize: function() {
    Elements.View.prototype.initialize.apply(this, arguments);
  },

  getInputName: function() {
    return this.options.baseName;
  },

  render: function() {
    Elements.View.prototype.render.apply(this, arguments);
  
    this.header = new Elements.ElementsEditor.ElementsEditorHeaderView(this.options.headerOptions);
    this.header.render();

    $(this.el).append(this.header.el).addClass(this.className);
    return this;
  },

  /**
   * Build ElementsEditorFormView for element.
   *
   * @param {Elements.Element} element
   * @return {ElementsEditor.ElementsEditorFormView}
   */
  buildFormForElement: function(element) {
    var formOptions = {
      parent: this,
      model: element,
    };
    return new Elements.ElementsEditor.ElementsEditorFormView(formOptions);
  },

  /**
   * Find form for element.
   *
   * @param {Elements.Element}
   * @return {ElementsEditor.ElementsEditorFormView}
   */
  findFormForElement: function(element) {
    return _.find(this.children, function(c) { 
      return (c instanceof Elements.ElementsEditor.ElementsEditorFormView && c.model.cid === element.cid); 
    });
  },

  showForm: function(form) {
    _.each(this.children, function(c) {
      if(c instanceof Elements.ElementsEditor.ElementsEditorFormView) {
        if(c === form) $(c.el).show();
        else $(c.el).hide();
      }
    }, this);
  },

  hideAllForms: function() {
    _.each(this.children, function(c) {
      if(c instanceof Elements.ElementsEditor.ElementsEditorFormView) {
        $(c.el).hide();
      }
    }, this);
  },

  /**
   * Add element editor view to widget body.
   *
   * @param {Elements.Element}
   * @return {ElementsEditor.ElementsEditorFormView}
   */
  addElement: function(element) {
    var form;
    // return form if already exist
    if((form = this.findFormForElement(element)))
      return form;

    // build new form view for element
    form = this.buildFormForElement(element);

    // add new form
    $(this.el).append(form.render().el);
    this.showForm(form);

    // emit DOMNodeInserted event
    form.trigger('view:DOMNodeInserted');
     
    return form;
  }

});
