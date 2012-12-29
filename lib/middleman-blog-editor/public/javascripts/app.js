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

    var editor = CKEDITOR.replace(this.get('elementId'));

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

App.DateField = Ember.TextField.extend({
  didInsertElement: function() {
    this._super();

    var self = this;
    this.$().datepicker({
      dateFormat: "yy/mm/dd",
      onSelect: function(d) {
        Ember.run.later(function() {
          self._elementValueDidChange();
        }, 100);
      }
    });
  },

  willDestroyElement: function() {
    this._super();

    this.$().datepicker('destroy');
  }
});

var pad = function(num) {
  return num < 10 ? "0"+num : ""+num;
};

App.Frontmatter = DS.Model.extend({
  key: DS.attr('string'),
  value: DS.attr('string'),
  valueBoolean: DS.attr('boolean', { key: 'value' }),
  article: DS.belongsTo('App.Article')
});

App.Article = DS.Model.extend({
  slug: DS.attr('string'),
  body: DS.attr('string'),
  engine: DS.attr('string'),
  date: DS.attr('date'),
  frontmatters: DS.hasMany('App.Frontmatter'),

  dateString: function(key, value) {
    // getter
    if (arguments.length === 1) {
      var d = this.get('date');
      if (Ember.isEmpty(d)) { return null; }

      return d.getUTCFullYear() + '/' + pad(d.getUTCMonth()+1) + '/' + pad(d.getUTCDate());
    } else {
      if (value.search(/^\d{4}-\d{2}-\d{2}$/) !== -1){
        value += "T00:00:00Z";
      }

      this.set('date', new Date(value));
      return value;
    }
  }.property('date'),

  published: function() {
    var fm = this.get('frontmatters');
    var row = fm.findProperty('key', 'published');
    return Ember.isNone(row) ? true : row.get('valueBoolean');
  }.property('frontmatters.@each'),

  title: function() {
    var fm = this.get('frontmatters');
    var row = fm.findProperty('key', 'title');
    return Ember.isNone(row) ? null : row.get('value');
  }.property('frontmatters.@each'),

  tags: function() {
    var fm = this.get('frontmatters');
    var row = fm.findProperty('key', 'tags');
    return Ember.isNone(row) ? null : row.get('value');
  }.property('frontmatters.@each'),

  tagsArray: function() {
    var tagsString = this.get('tags');
    var arr = Em.isEmpty(tagsString) ? [] : tagsString.split(',');
    return Ember.A(arr);
  }.property('tags'),

  frontMatterPairs: function() {
    var fm = this.get('frontmatters');
    return Ember.A(fm.filter(function(k) {
      return ['title', 'tags', 'published'].indexOf(k.get('key')) < 0;
    }));
  }.property('frontmatters.@each'),

  permalink: function() {
    var permalink = URL_FORMAT;

    var d = this.get('date');
    if (!Em.isEmpty(d)) {
      permalink = permalink.replace(':year', d.getUTCFullYear());
      permalink = permalink.replace(':month', pad(d.getUTCMonth()+1));
      permalink = permalink.replace(':day', pad(d.getUTCDate()));
    }

    permalink = permalink.replace(':title', this.get('slug'));

    return permalink;
  }.property('date', 'slug')
});

App.Router = Ember.Router.extend({
  root: Ember.Route.extend({
    goHome:  Ember.Route.transitionTo('root.index'),

    index: Ember.Route.extend({
      route: '/',

      editArticle: Ember.Route.transitionTo('root.edit'),

      connectOutlets: function(router, context){
        router.get('articlesController').set('content', App.Article.all());
        router.get('applicationController').connectOutlet('body', 'articles');
      }
    }),

    edit: Ember.Route.extend({
      route: '/edit/:id',

      connectOutlets: function(router, context) {
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

      deserialize: function(router, context) {
        return App.Article.find(context.id);
      }
    })
  })
});

App.initialize();