class HomeController < ApplicationController
  def index
    @photos = Photo.where(published: true).order(:order)
  end
end
