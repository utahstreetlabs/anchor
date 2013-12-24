require 'rubygems'
require 'bundler'

Bundler.require

$LOAD_PATH << File.join(File.dirname(__FILE__), 'lib')

require 'dino/kaminari'
require 'anchor/apps/comments'
require 'anchor/apps/comments/flags'
require 'anchor/apps/comments/replies'
require 'anchor/apps/listings'
require 'anchor/apps/listings/comments'
require 'anchor/apps/users'
require 'anchor/apps/root'

use Rack::ShowExceptions
use LogWeasel::Middleware

Kaminari.configure do |config|
  config.default_per_page = 100
end

apps = [
  Anchor::CommentsApp,
  Anchor::CommentFlagsApp,
  Anchor::CommentRepliesApp,
  Anchor::ListingsApp,
  Anchor::ListingCommentsApp,
  Anchor::UsersApp,
  Anchor::RootApp
]

run Rack::Cascade.new apps
