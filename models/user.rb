class User
  attr_accessor :identifier, :username, :name, :email
    
  def initialize(identifier, username, name, email)
    @identifier     = identifier
    @username = username
    @name = name
    @email = email
  end
  
end