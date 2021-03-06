require 'sinatra'
load "lib/ascension.rb"
require 'json'

def playing_on_command_line?
  false
end

def db
  Mongo::Connection.new.db('ascension-web')
end

#Choices.setup_chooser!

helpers do
  def id_hash
    {:_id => BSON::ObjectId(params[:id])}
  end
  def set_origin
    response['Access-Control-Allow-Origin'] = 'http://localhost:4567'
  end
  def game
    set_origin
    @game ||= Game.collection.find_one_object(id_hash)
  end
end

get "/reset" do
  Game.reset!
  game.to_json
end

get "/games" do
  set_origin
  Game.collection.find_objects.to_a.to_json
end

get "/games/:id" do
  game.to_json
end

get "/games/:id/play_card/:card" do
  set_origin
  side = game.turn_manager.current_side
  if params[:card] == "All"
    side.hand.each { |card| side.play(card) }
  else
    card = side.hand.find { |x| x.name == params[:card] }
    raise "no card #{params[:card]}" unless card
    side.play(card)
  end
  game.mongo.save!
  game.to_json
end

get "/games/:id/acquire_card/:card" do
  set_origin
  side = game.turn_manager.current_side
  card = game.center_wc.find { |x| x.name == params[:card] }
  raise "no card #{params[:card]}" unless card
  side.engage(card)
  game.mongo.save!
  game.to_json
end

get "/games/:id/advance" do
  set_origin
  game.turn_manager.advance!
  game.mongo.save!
  game.to_json
end

get "/games/:id/choose_option/:choice_id/:card" do
  set_origin

  side = game.turn_manager.current_side
  choice = side.choices.find { |x| x.choice_id.to_s == params[:choice_id].to_s }
  card = game.find_card params[:card]

  choice.execute! card
  game.mongo.save!
  game.to_json
end