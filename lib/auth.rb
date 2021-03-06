require "cgi"

class Auth
  URL            = "http://4ye.mindpin.com/account/sign_in"
  COOKIE_KEY     = "current_user_email"
  USER_INFO_URL  = "http://4ye.mindpin.com/api/user_info"

  def initialize(login, password, context)
    @login    = login
    @password = password
    @context  = context
  end

  def login!
    @response = JSON.parse(RestClient.post(URL, params))
    find_or_create_user_store!
    set_cookie!
    true
  end

  def self.current_store(context)
    email = context.cookies[COOKIE_KEY]
    return if !email
    UserStore.find_by(email: CGI.unescape(email))
  end

  def self.find_by_secret(secret)
    store = UserStore.where(secret: secret).first
    return store if !store.blank?
    return create_user_store_by_info(secret)
  end

  private

  def set_cookie!
    @context.cookies[COOKIE_KEY] = @store.email
  end

  def find_or_create_user_store!
    if @response.is_a?(Hash)
      @store = UserStore.find_or_create_by(email: @response["email"])
      @store.update_attributes(name: @response["name"], avatar: @response["avatar"], uid: @response["id"], secret: @response["secret"])
      @store.save
    end
  end

  def params
    {user: {login: @login, password: @password}}
  end

  def self.create_user_store_by_info(secret)
    user_info = JSON.parse(RestClient.get(user_info_url(secret)))
    return if !user_info["id"]
    store = UserStore.find_or_create_by(email: user_info["email"])
    store.update_attributes(name: user_info["name"], avatar: user_info["avatar"], uid: user_info["id"], secret: user_info["secret"])
    store.save
    store
  end

  def self.user_info_url(value)
    "#{USER_INFO_URL}?secret=#{value}"
  end
end
