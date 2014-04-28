require "bundler"
Bundler.setup(:default)
require "sinatra"
require "sinatra/cookies"
require "sinatra/reloader"
require 'sinatra/assetpack'
require "pry"
require "sinatra"
require 'haml'
require 'sass'
require 'coffee_script'
require 'yui/compressor'
require 'sinatra/json'
require "rest_client"
require 'mongoid'
require "multi_json"
require File.expand_path("../../config/env",__FILE__)

require "./lib/user_store"
require "./lib/auth"
require "./lib/trange"

class RangeData < Sinatra::Base
  configure :development do
    register Sinatra::Reloader
  end

  set :views, ["templates"]
  set :root, File.expand_path("../../", __FILE__)
  set :cookie_options, :domain => nil
  register Sinatra::AssetPack

  assets {
    serve '/js', :from => 'assets/javascripts'
    serve '/css', :from => 'assets/stylesheets'

    js :application, "/js/application.js", [
      '/js/jquery-1.11.0.min.js',
      '/js/**/*.js'
    ]

    css :application, "/css/application.css", [
      '/css/**/*.css'
    ]

    css_compression :yui
    js_compression  :uglify
  }

  helpers Sinatra::Cookies

  helpers do
    def current_store
      Auth.current_store(self)
    end

    def res(response)
      @res ||= Hash.new
      @res.merge!(response)
    end

    def respond_with(&block)
      store = Auth.find_by_secret(params[:secret])
      return 401 if !store
      res user_id: store.uid, user_name: store.name, url: params[:url]
      block.call(store)
      res_value = MultiJson.dump(@res)
      content_type :json
      return res_value if !params[:callback]
      content_type :js
      "#{params[:callback]}(#{res_value})"
    end
  end

  before do
    headers("Access-Control-Allow-Origin" => "*")
  end

  get "/" do
    redirect to("/login") if !current_store
    haml :index
  end

  get "/login" do
    haml :login
  end

  post "/login" do
    begin
      Auth.new(params[:login], params[:password], self).login!
      200
    rescue
      401
    end
  end

  post "/write_range" do
    respond_with do |store|
      range  = store.t_ranges.find_or_create_by(url: params[:url], data: params[:range_data])
      ranges = store.t_ranges.where(url: params[:url]).map(&:res)
      res ranges: ranges, range_data: range.data
    end
  end

  get "/read_ranges" do
    respond_with do |store|
      ranges = store.t_ranges.where(url: params[:url]).map(&:res)
      res ranges: ranges
    end
  end
end
