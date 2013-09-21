class HomeController < ApplicationController
  skip_authorization_check

  def index
  end

  def begin
    @photos = Photo.where(published: true).order(:order)
  end

end
