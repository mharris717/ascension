require 'mharris_ext'
require 'rchoice'

class Array
  def sum
    inject { |s,i| s + i }
  end
end

class Object
  def klass
    self.class
  end
end

class Events
  def fire(event)
    
  end
end

class Game
  fattr(:sides) { [] }
  fattr(:center) { Center.new(:game => self) }
  fattr(:void) { Void.new }
  fattr(:honor) { 60 }
  fattr(:deck) { CenterDeck.starting }
  fattr(:center_wc) { CenterWithConstants.new(:game => self) }
end

class Side
  include FromHash
  attr_accessor :game
  fattr(:discard) { Discard.new(:side => self) }
  fattr(:deck) { PlayerDeck.starting(:side => self) }
  fattr(:hand) { Hand.new(:side => self) }
  fattr(:played) { Played.new(:side => self) }
  fattr(:constructs) { Constructs.new(:side => self) }
  fattr(:honor) { 0 }
  def draw_hand!
    5.times { draw_one! }
  end
  def draw_one!
    hand << deck.draw_one
  end
  def play(card)
    played << card
    hand.remove(card)
  end
  def acquire_free(card)
    discard << card
    game.center_wc.remove(card)
    fire_event Event::CardPurchased.new(:card => card)
  end
  def purchase(card)
    acquire_free(card)
    #card.apply_abilities(self)
    played.pool.runes -= card.rune_cost
  end
  def defeat(monster)
    game.void << monster
    game.center.remove(monster) unless monster.name =~ /cultist/i && !game.center.include?(monster)
    
    fire_event Event::MonsterKilled.new(:card => monster, :center => true)
    
    monster.apply_abilities(self)
    played.pool.power -= monster.power_cost
  end
  def end_turn!
    played.discard!
    hand.discard!
    constructs.apply!
    draw_hand!
    
  end
  def total_cards
    [hand,played,deck,discard].map { |x| x.size }.sum
  end
  
  fattr(:events) { Event::Events.new(:side => self) }
  def fire_event(event)
    events << event
  end
  def other_side
    game.sides.reject { |x| x == self }.first
  end
  def print_status!
    puts "Center " + game.center.to_s_cards
    puts "Hand " + hand.to_s_cards
    puts "Played " + played.to_s_cards
    puts "Constructs " + constructs.to_s_cards unless constructs.empty?
    puts "Pool " + played.pool.to_s
  end
end

%w(card cards ability pool events parse).each do |f|
  require File.dirname(__FILE__) + "/ascension/#{f}"
end