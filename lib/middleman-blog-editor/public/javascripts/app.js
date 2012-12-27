var App = Ember.Application.create({
  ready: function() {
    this.get('router.store').findAll(App.Article);
  }
});

App.RESTAdapter = DS.RESTAdapter.extend({

});

App.Store = DS.Store.extend({
  revision: 10,

  adapter: DS.RESTAdapter.create({
    bulkCommit: false,
    namespace: ROOT_DIR + '/api'
  })
});

App.ApplicationController = Ember.Controller.extend();
App.ArticlesController = Ember.ArrayController.extend();
App.EditArticleController = Ember.ObjectController.extend();

App.ApplicationView = Ember.View.extend({
  templateName: 'application'
});

App.ArticlesView = Ember.View.extend({
  templateName: 'articles'
});

App.EditArticleView = Ember.View.extend({
  templateName: 'edit-article'
});

App.CKEditorView = Ember.View.extend({
  isInline: false,

  value: "",

  _valueDidChange: function() {
    var editor = this.get('editor');
    if (editor && (this.get('value') != editor.getData())) {
      editor.setData(this.get('value'));
    } else {
      this.$().html(this.get('value'));
    }
  }.observes('value'),

  didInsertElement: function() {
    this._super();

    var editor;

    if (this.get('isInline')) {
      CKEDITOR.disableAutoInline = true;
      editor = CKEDITOR.inline(this.get('elementId'));
    } else {
      CKEDITOR.disableAutoInline = false;
      editor = CKEDITOR.replace(this.get('elementId'));
    }

    editor.setData(this.get('value'));
    this.set("editor", editor);
    
    var self = this;
    var updateViewContent = function() {
      self.set("value", editor.getData());
    };

    editor.on("focus", function() {
      updateViewContent();
    });

    editor.on("blur", function() {
      updateViewContent();
    });

    editor.on("key", function() {
      updateViewContent();
    });
  },

  willDestroyElement: function() {
    this.get('editor').destroy(true);
  }
});

App.Article = DS.Model.extend({
  slug: DS.attr('string'),
  title: DS.attr('string'),
  body: DS.attr('string')
});

App.Router = Ember.Router.extend({
  root: Ember.Route.extend({
    index: Ember.Route.extend({
      route: '/',

      editArticle:  Ember.Route.transitionTo('root.edit'),

      connectOutlets:  function(router, context){
        router.get('articlesController').set('content', App.Article.all());
        router.get('applicationController').connectOutlet('body', 'articles');
      }

    }),

    edit: Ember.Route.extend({
      route: '/edit/:id',

      connectOutlets:  function(router, context) {
        router.get('editArticleController').set('content', context);
        router.get('applicationController').connectOutlet('body', 'editArticle');
      },

      serialize: function(router, context) {
        var id = context.get('id');
        if (id === 'undefined') { id = context.get('slug'); }
        
        return {
          id: id
        };
      },

      deserialize: function(router, context){ 
        return App.Article.find(context.id);
      }

    })
  })
});

App.initialize();