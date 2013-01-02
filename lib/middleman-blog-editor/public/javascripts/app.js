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
App.ArticlesController = Ember.ArrayController.extend({
  sortProperties: ['date'],
  sortAscending: false,

  publishedCount: function() {
    return Ember.A(this.filterProperty("published", true)).get('length');
  }.property("@each.published"),

  unpublishedCount: function() {
    return Ember.A(this.filterProperty("published", false)).get('length');
  }.property("@each.published"),

  tagsCount: function() {
    return Ember.A(this.reduce(function(sum, a) {
      sum.pushObjects(a.get('tagsArray'));
      return sum;
    }, Ember.A([])).uniq()).get('length');
  }.property("@each.tagsArray")
});
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

App.Article = DS.Model.extend({
  slug: DS.attr('string'),
  // body: DS.attr('string'),
  raw: DS.attr('string'),
  engine: DS.attr('string'),
  source: DS.attr('string'),
  frontmatter: DS.attr('string'),
  date: DS.attr('date'),

  init: function() {
    this._frontmatter = {};

    this._super();
  },

  _frontmatterDidChange: function() {
    if (this.get('frontmatter')) {
      this._frontmatter = JSON.parse(this.get('frontmatter')) || {};
    }
  }.observes('frontmatter'),

  _updateFrontmatterString: function() {
    this.set('frontmatter', JSON.stringify(this._frontmatter));
  }.observes('frontmatters'),

  setFrontmatter: function(key, value) {
    this._frontmatter[key] = value;
    this._updateFrontmatterString();
  },

  getFrontmatter: function(key) {
    return this._frontmatter[key];
  },

  removeFrontmatter: function(key) {
    delete this._frontmatter(key);
    this._updateFrontmatterString();
  },

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

  published: function(key, value) {
    if (arguments.length === 1) {
      var val = this.getFrontmatter('published');
      return typeof val === "undefined" ? true : val;
    } else {
      this.setFrontmatter('published', value);
      return value;
    }
  }.property('frontmatter'),

  title: function(key, value) {
    if (arguments.length === 1) {
      return this.getFrontmatter('title');
    } else {
      this.setFrontmatter('title', value);
      return value;
    }
  }.property('frontmatter'),

  tags: function() {
    return this.getFrontmatter('tags');
  }.property('frontmatter'),

  tagsArray: function() {
    var tagsString = this.get('tags');
    var arr = Em.isEmpty(tagsString) ? [] : tagsString.split(',');
    return Ember.A(arr);
  }.property('tags'),

  frontMatterPairs: function() {
    var pairs = [];

    for (var key in this._frontmatter) {
      if (this._frontmatter.hasOwnProperty(key)) {
        if (['title', 'tags', 'date', 'published', 'blog_editor_id'].indexOf(key) < 0) {
          pairs.push({ key: key, value: this._frontmatter[key] });
        }
      }
    }

    return Ember.A(pairs);
  }.property('frontmatter'),

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

      deleteArticle: function(router, evt) {
        if (confirm('Sure?')) {
          evt.context.deleteRecord();
          router.get('store.defaultTransaction').commit();
        }
      },

      createArticle: function(router) {
        router.transitionTo('root.create');
      },

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
        return {
          id: context.get('id')
        };
      },

      deserialize: function(router, context) {
        return App.Article.find(context.id);
      }
    }),

    create: Ember.Route.extend({
      route: '/create',

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
        var model = router.get('editArticleController.content');
        model.addObserver('id', null, function() {
          router.transitionTo('root.edit', model);
        });

        router.get('store.defaultTransaction').commit();
      },

      connectOutlets: function(router, context) {
        var newModel = App.Article.createRecord({
          slug: 'un-named',
          // body: '<p>New Article...</p>',
          raw: 'New Article...',
          engine: 'erb',
          // source: DS.attr('string'),
          date: (new Date())
        });
        newModel.setFrontmatter('title', 'New Article');
        
        router.get('editArticleController').set('content', newModel);
        router.get('applicationController').connectOutlet('body', 'editArticle');
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