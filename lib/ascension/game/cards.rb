class Cards
  include FromHash
  include Enumerable
  setup_mongo_persist :cards
  attr_accessor :side, :game
  fattr(:game) { side.game }
  fattr(:cards) { [] }
  def <<(c)
    cards << c
  end
  def remove(c)
    raise "remove arg is null" unless c
    unless cards.include?(c)
      cstr = map { |x| "#{x.name}:#{x.card_id}" }.join(",")
      raise "#{c}:#{c.card_id} not here in #{klass}, do have #{cstr}"
    end 
    self.cards -= [c]
  rescue(BadCardEquals) => exp
    res = "#{exp.message}, cards is #{inspect}"
    raise res
  end
  def each(&b)
    cards.each(&b)
  end
  def shuffle!
    self.cards = cards.sort_by { |x| rand() }
  end
  def empty?
    size == 0
  end
  def size
    cards.size
  end
  def first
    cards.first
  end
  def last
    cards.last
  end
  def pop
    cards.pop
  end
  def index(obj)
    cards.index(obj)
  end
  def clear!
    self.cards = []
  end
  def include?(c)
    cards.include?(c)
  rescue(BadCardEquals) => exp
    res = "#{exp.message}, cards is #{inspect}"
    raise res
  end
  def banish(card)
    remove(card)
    game.void << card
  end
  def []=(i,card)
    cards[i] = card
  end
  def [](i)
    cards[i]
  end
  def to_s_cards
    map { |x| x.name }.join(" | ")
  end
  def get_one(name)
    res = find { |x| x.name == name }
    raise "couldn't find #{name}" unless res
    self.cards -= [res]
    res
  end
  def hydrate!
    self.cards = map { |x| x.hydrated }
  end
  def reverse
    cards.reverse
  end
end

class Discard < Cards; end

class PlayerDeck < Cards
  def draw_one
    fill_from_discard! if empty?
    cards.pop
  end
  def fill_from_discard!
    self.cards = side.discard.cards
    side.discard.cards = []
    shuffle!
  end
  def self.starting(ops={})
    res = new(ops)
    8.times { res << Card::Hero.apprentice }
    2.times { res << Card::Hero.militia }
    res.shuffle!
    res
  end
end

class Hand < Cards
  def play_all!
    while size > 0
      side.play(first)
    end
  end
  def discard!
    each { |c| side.discard << c }
    clear!
  end
  def discard(card)
    remove(card)
    side.discard << card
  end
end

class Played < Cards
  setup_mongo_persist :cards, :pool
  fattr(:pool) { Pool.new }

  def apply_existing_events(card)
    card.triggers.each do |trigger|
      if trigger.respond_to?(:unite) && trigger.unite
        side.events.each do |event|
          trigger.call event,side
        end
      end
    end
  end
  def apply(card)
    card.apply_abilities(side)
    apply_existing_events(card)
    

    pool.runes += card.runes
    pool.power += card.power
    
  end
  def <<(card)
    super
    apply(card)
    
    
    
    if card.kind_of?(Card::Construct)
      remove(card)
      side.constructs << card
    end

    side.fire_event(Event::CardPlayed.new(:card => card))
  end
  def discard!
    each { |c| side.discard << c }
    clear!
    self.pool!
  end
end

class Void < Cards; end

module Selectable
  def engageable_cards(side)
    select { |x| can?(x,side) }
  end
  def can?(card,side)
    if card.monster?
      raise card.name unless card.power_cost
      side.played.pool.power >= card.power_cost
    else
      side.played.pool.can_purchase?(card)
    end
  end
end

class Center < Cards
  def fill!
    (0...size).each do |i|
      if self[i].name == 'Dummy'
        card = game.deck.pop
        handle_appear(card)
        self[i] = card
      end
    end

    while size < 6
      card = game.deck.pop
      handle_appear(card)
      self << card
    end
  end
  def handle_appear(card)
    card.fate_abilities.each do |ability|
      game.sides.each do |side|
        ability.call(side)
      end
    end
  end
  def remove(c)
    raise "#{c} not here" unless include?(c)
    i = index(c)
    self[i] = Card.dummy
    fill!
  end
  def banish(card)
    super
    fill!
  end
end

class CenterWithConstants < Cards
  attr_accessor :game
  include FromHash
  include Selectable
  fattr(:constant_cards) do
    [Card::Hero.mystic,Card::Hero.heavy_infantry,Card::Monster.cultist]
  end
  def cards
    game.center.cards + constant_cards
  end
  def size
    cards.size
  end
  def remove(card)
    return nil if constant_cards.map { |x| x.name }.include?(card.name)
    game.center.remove(card)
  end
  def method_missing(sym,*args,&b)
    game.center.send(sym,*args,&b)
  end
end

class CenterDeck < Cards
  class << self
    def starting
      res = new
      Parse::InputFile.new.cards.each { |c| res << c }
      res.shuffle!
      res
    end
  end
end

class Constructs < Cards
  def apply!
    each { |c| side.played.apply(c) }
  end
  def discard(card)
    remove(card)
    side.discard << card
  end
end

class Trophies < Cards
  def play(card)
    raise "nil card" unless card
    raise "trying to play trophy card that doesn't have a trophy, #{card.inspect}" unless card.trophy
    remove(card)
    side.played.apply(card.trophy)
  end
end