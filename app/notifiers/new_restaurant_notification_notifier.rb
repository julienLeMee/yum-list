# To deliver this notification:
#
# NewRestaurantNotificationNotifier.with(restaurant: @restaurant, sender: current_user).deliver(@friends)

class NewRestaurantNotificationNotifier < ApplicationNotifier
  deliver_by :database

  def message
    sender_name = params[:sender].name.present? ? params[:sender].name : params[:sender].email
    "#{sender_name} a ajouté un nouveau restaurant :\n#{params[:restaurant].name}"
  end

  def url
    Rails.application.routes.url_helpers.restaurant_path(params[:restaurant])
  end
end

