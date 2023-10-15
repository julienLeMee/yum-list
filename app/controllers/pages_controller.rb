class PagesController < ApplicationController
  def map
    @google_map_key = ENV['GOOGLE_MAP_KEY']
  end
end
