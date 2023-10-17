class PagesController < ApplicationController
  def map
    @google_map_key = ENV['GOOGLE_MAPS_API_KEY']
  end
end
