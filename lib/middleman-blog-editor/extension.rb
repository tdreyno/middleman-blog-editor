# Blog Editor extension
module Middleman::BlogEditor

  # Setup extension
  class << self

    # Once registered
    def registered(app)
    end
    alias :included :registered
  end
end
