# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "middleman-blog-editor/version"

Gem::Specification.new do |s|
  s.name        = "middleman-blog-editor"
  s.version     = Middleman::BlogEditor::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Thomas Reynolds"]
  s.email       = ["me@tdreyno.com"]
  s.homepage    = "http://middleman-blog-editor.awardwinningfjords.com/"
  s.summary     = %q{WYSIWYG blog editor for Middleman}
  s.description = %q{WYSIWYG blog editor for Middleman}

  s.rubyforge_project = "middleman-blog-editor"

  s.files         = `git ls-files -z`.split("\0")
  s.test_files    = `git ls-files -z -- {fixtures,features}/*`.split("\0")
  s.require_paths = ["lib"]
  
  s.add_dependency("sinatra")
  s.add_dependency("middleman-core", ["3.0.8.pre.1"])
  s.add_dependency("middleman-blog", [">= 3.1.0"])
end