# encoding: utf-8

require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name = "ascension"
  gem.homepage = "http://github.com/mharris717/ascension"
  gem.license = "MIT"
  gem.summary = %Q{ascension}
  gem.description = %Q{ascension}
  gem.email = "mharris717@gmail.com"
  gem.authors = ["Mike Harris"]
  # dependencies defined in Gemfile
end
Jeweler::RubygemsDotOrgTasks.new

require 'rspec/core'
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = FileList['spec/**/*_spec.rb']
end

RSpec::Core::RakeTask.new(:rcov) do |spec|
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
end

task :default => :spec

require 'rdoc/task'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "ascension #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

task :environment do
  load "lib/ascension.rb"
end

task :dump_game => :environment do
  require 'json'
  obj = Game.collection.find.to_a[0]
  str = obj.to_json
  File.create "vol/game.json",str

  require 'pp'

  File.open("vol/game_pp.json","w") do |f|
    PP.pp(obj,f)
  end
end

task :reset_game => :environment do
  Game.collection.remove
  Game.reset!
  puts Game.collection.find_one_object.mongo_id
end



