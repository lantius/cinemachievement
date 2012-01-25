require 'json'

class User
  attr_accessor :identifier, :username, :name, :email
    
  def initialize(identifier, username, name, email)
    @identifier = identifier
    @username = username
    @name = name
    @email = email
  end
  
  def to_json(*a)
    {
      'json_class'   => self.class.name,
      'data'         => {'identifier' => @identifier, 'username' => @username, 'name' => @name, 'email' => @email }
    }.to_json(*a)
  end
 
  def self.json_create(o)
    new(o['data']['identifier'], o['data']['username'],  o['data']['name'], o['data']['email'])
  end
  
end