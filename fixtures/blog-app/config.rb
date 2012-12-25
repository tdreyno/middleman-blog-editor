activate :blog do |blog|
  blog.sources = ":year/:month/:day/:title.html"
end

class Account
  def initialize(username, password, role)
    @username = username
    @password = password
    @role = role
  end

  def auth?(u, p)
    @username === u && @password === p
  end

  def admin?
    @role === 'admin'
  end

  def editor?
    @role === 'editor'
  end

  def readonly?
    @role === 'readonly'
  end
end

require 'cancan'
class Ability
  include ::CanCan::Ability

  def initialize(account)
    @user = account

    if @user.admin?
      can :manage, :all
    end

    if @user.editor?
      can [:edit, :read], :all
    end

    if @user.readonly?
      can :read, :all
    end
  end
end

activate :blog_editor do |editor|
  # Where to place the editor UI.
  editor.mount_at = "/editor"

  editor.accounts = [
    Account.new('admin', 'admin', 'admin'),
    Account.new('editor', 'editor', 'editor'),
    Account.new('readonly', 'readonly', 'readonly')
  ]
end