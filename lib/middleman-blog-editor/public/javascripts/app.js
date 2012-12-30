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

App.TooltipSpan = Ember.View.extend({
  title: null,
  content: null,

  tagName: "span",
  classNames: "has-tip tip-top".w(),

  attributeBindings: ['title'],

  template: Ember.Handlebars.compile('{{view.content}}'),

  didInsertElement: function() {
    this._super();
    $(document).foundationTooltips('reload');
  },

  _titleDidChange: function() {
    $(document).foundationTooltips('reload');
  }.observes("title"),

  willDestroyElement: function() {
    $(document).foundationTooltips('reload');
    this._super();
  }
});

App.SplitDropdown = Ember.View.extend({
  classNames: "small button split dropdown".w(),

  template: Ember.Handlebars.compile('{{view.content}}'),

  didInsertElement: function() {
    this._super();

    this.$('> ul', this).addClass('no-hover');
  }
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
  raw: DS.attr('string'),
  engine: DS.attr('string'),
  source: DS.attr('string'),
  date: DS.attr('date'),
  frontmatters: DS.hasMany('App.Frontmatter'),

  WYSIWYGable: function() {
    return this.get('engine') === 'erb';
  }.property('engine'),

  dateStringFull: function() {
    return this.get('date').toString();
  }.property('date'),

  dateString: function(key, value) {
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

  publishedRow: function() {
    var fm = this.get('frontmatters');
    return fm.findProperty('key', 'published');
  }.property('frontmatters.@each'),

  published: function(key, value) {
    var row = this.get('publishedRow');

    if (arguments.length === 1) {
      return Ember.isNone(row) ? true : row.get('valueBoolean');
    } else {
      row.set('valueBoolean', value);
      return value;
    }
  }.property('publishedRow'),

  titleRow: function() {
    var fm = this.get('frontmatters');
    return fm.findProperty('key', 'title');
  }.property('frontmatters.@each'),

  title: function(key, value) {
    var row = this.get('titleRow');

    if (arguments.length === 1) {
      return Ember.isNone(row) ? null : row.get('value');
    } else {
      row.set('value', value);
      return value;
    }
  }.property('titleRow'),

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
      return ['title', 'tags', 'date', 'published'].indexOf(k.get('key')) < 0;
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
  errorOnUnhandledEvent: false,

  root: Ember.Route.extend({

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

      goHome: function(router) {
        this.cancel.apply(this, arguments);
      },

      cancel: function(router) {
        var transaction = router.get('store.defaultTransaction');


        var isDirty = !(transaction.get('buckets.created').isEmpty() && transaction.get('buckets.updated').isEmpty() && transaction.get('buckets.deleted').isEmpty());

        if (isDirty) {
          if (confirm('Do you want to discard your changes?')) {
            transaction.rollback();
            router.transitionTo('root.index');
          }
        } else {
          router.transitionTo('root.index');
        }
      },

      save: function(router) {
        router.get('store.defaultTransaction').commit();
      },

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

(function ($, window, undefined) {
  'use strict';

  var $doc = $(document),
      Modernizr = window.Modernizr;

  $(document).ready(function() {
    $.fn.foundationAlerts           ? $doc.foundationAlerts() : null;
    $.fn.foundationButtons          ? $doc.foundationButtons() : null;
    $.fn.foundationAccordion        ? $doc.foundationAccordion() : null;
    $.fn.foundationNavigation       ? $doc.foundationNavigation() : null;
    $.fn.foundationTopBar           ? $doc.foundationTopBar() : null;
    $.fn.foundationCustomForms      ? $doc.foundationCustomForms() : null;
    $.fn.foundationMediaQueryViewer ? $doc.foundationMediaQueryViewer() : null;
    $.fn.foundationTabs             ? $doc.foundationTabs({callback : $.foundation.customForms.appendCustomMarkup}) : null;
    $.fn.foundationTooltips         ? $doc.foundationTooltips() : null;
    $.fn.foundationMagellan         ? $doc.foundationMagellan() : null;
    $.fn.foundationClearing         ? $doc.foundationClearing() : null;

    $.fn.placeholder                ? $('input, textarea').placeholder() : null;
  });

  // UNCOMMENT THE LINE YOU WANT BELOW IF YOU WANT IE8 SUPPORT AND ARE USING .block-grids
  // $('.block-grid.two-up>li:nth-child(2n+1)').css({clear: 'both'});
  // $('.block-grid.three-up>li:nth-child(3n+1)').css({clear: 'both'});
  // $('.block-grid.four-up>li:nth-child(4n+1)').css({clear: 'both'});
  // $('.block-grid.five-up>li:nth-child(5n+1)').css({clear: 'both'});

  // Hide address bar on mobile devices (except if #hash present, so we don't mess up deep linking).
  if (Modernizr.touch && !window.location.hash) {
    $(window).load(function () {
      setTimeout(function () {
        window.scrollTo(0, 1);
      }, 0);
    });
  }

})(jQuery, this);