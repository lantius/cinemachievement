require 'json'

class User
  attr_accessor :identifier, :rev, :username, :name, :email, :seenfilms
    
  def initialize(identifier, rev, username, name, email, seenfilms)
    @identifier = identifier
    @rev = rev
    @username = username
    @name = name
    @email = email
    @seenfilms = seenfilms
  end
  
  def to_json(*a)
    o = {
      'json_class'   => self.class.name,
      'data'         => {'identifier' => @identifier, 'username' => @username, 'name' => @name, 'email' => @email, 'seenfilms' => @seenfilms }
    }
    if @rev
      o['_rev'] = @rev
    end
    
    o.to_json(*a)
  end
 
  def self.json_create(o)
    new(o['data']['identifier'], o['_rev'], o['data']['username'],o['data']['name'], o['data']['email'], o['data']['seenfilms'])
  end
  
end