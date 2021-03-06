require 'json'
module JsonPersist
  def as_json(*args)
    to_json_hash
  end
  def new_hash_json(attr,h,obj)
    if obj.can_mongo_convert?
      if obj.respond_to?(:select) && false
        h.merge(attr => obj.to_mongo_hash)
      elsif [Numeric,String].any? { |c| obj.kind_of?(c) }
        h.merge(attr => obj)
      else
        h.merge(attr => obj.as_json) 
      end
    else
      h
    end
  rescue
    return h
  end
  def full_addl_json_attributes
    res = []
    res += addl_json_attributes if respond_to?(:addl_json_attributes)
    res += self.class.full_addl_json_attributes if self.class.respond_to?(:full_addl_json_attributes)
    res.flatten.uniq
  end
  def to_json_hash
    restricted = []
    restricted = restricted_json_attributes.map { |x| x.to_s } if respond_to?(:restricted_json_attributes)

    res = mongo_child_attributes.inject({}) do |h,attr| 
      #obj = 
      #raise "#{attr} is nil" unless obj
      restricted.include?(attr.to_s) ? h : new_hash_json(attr,h,send(attr)) 
    end
    klass.mongo_reference_attributes.each do |attr|
      val = send(attr)
      res[attr] = val.to_mongo_ref_hash if val && !restricted.include?(attr.to_s)
    end
    if respond_to?(:addl_json_attributes) && true
      #puts "in addl_json_attributes part"
      addl = [full_addl_json_attributes].flatten.select { |x| x }
      addl.each do |attr|
        #puts "addl attr #{attr}"
        res = new_hash_json(attr,res,send(attr)) unless restricted.include?(attr.to_s)
      end
    end
    res
  end
  def to_json(*args)
    as_json(*args).to_json
  end

  module ClassMethods
    def full_addl_json_attributes
      res = []
      res += addl_json_attributes if respond_to?(:addl_json_attributes)
      res += superclass.full_addl_json_attributes if superclass.respond_to?(:full_addl_json_attributes)
      res.flatten.uniq
    end
  end

  def self.included(mod)
    super
    mod.send(:extend,ClassMethods)
  end
end

module MongoHash
  def as_json(*args)
    res = {}
    each do |k,v| 
      v = v.as_json(*args) if v.respond_to?(:as_json)
      res[k.safe_to_mongo_hash.to_mongo_key] = v
    end
    res
  end
end

class Array
  def as_json(*args)
    map do |obj|
      obj.respond_to?(:as_json) ? obj.as_json(*args) : obj
    end
  end
end

class TrueClass
  def as_json(*args)
    self
  end
end

class FalseClass
  def as_json(*args)
    self
  end
end


class Class
  def setup_mongo_persist(*attrs)
    include MongoPersist
    include JsonPersist
    define_method(:mongo_attributes) do
      attrs.flatten.map { |x| x.to_s }
    end
  end
end