require 'bundler'
require 'yaml'

Bundler.require

$LOAD_PATH << File.join(File.dirname(__FILE__), '..')

ENV['RACK_ENV'] ||= 'development'

class Anchor < Thor
  CONFIG = File.join('config', 'mongoid.yml')

  desc "rebuild_from_staging", "rebuilds the development database from staging"
  def rebuild_from_staging
    dev = config['development']
    st = config['staging']
    run_command(%Q/mongo #{dev['database']} --eval "db.runCommand('dropDatabase')"/)
    run_command(%Q/mongo #{dev['database']} --eval "db.copyDatabase('#{st['database']}', '#{dev['database']}', '#{st['host']}')"/)
  end

  desc "list_commenters", "get a list of commenters. may include dupes."
  def list_commenters
    load_mongoid
    require 'anchor/models/listing'

    Listing.all.each do |listing|
      listing.comments.each do |comment|
        list_commenters_for_comment(comment)
      end
    end
  end

protected

  def list_commenters_for_comment(comment)
    puts comment.user_id
    comment.replies.each {|c| list_commenters_for_comment(c) }
  end

  def config
    @config ||= YAML.load_file(CONFIG)
  end

  def load_mongoid
    Mongoid.load!(CONFIG)
    Mongoid.logger = Logger.new(File.join('log', "#{ENV['RACK_ENV']}.log"))
    Mongoid.logger.level = Logger::INFO
  end

  def run_command(command)
    say_status :run, command
    IO.popen("#{command} 2>&1") do |f|
      while line = f.gets do
        puts line
      end
    end
  end
end
