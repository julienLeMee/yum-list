# To deliver this notification:
#
# NewRestaurantNotificationNotifier.with(restaurant: @restaurant, sender: current_user).deliver(@friends)

class NewRestaurantNotificationNotifier < ApplicationNotifier
  deliver_by :database
  
  # Désactivé temporairement - notifications push
  # deliver_by :custom, class: "WebPushChannel" do |config|
  #   config.enqueue = false
  # end

  def message
    sender_name = params[:sender].name.present? ? params[:sender].name : params[:sender].email
    restaurant_name = params[:restaurant].name
    "#{sender_name} a ajouté un nouveau restaurant : #{restaurant_name}"
  end

  def url
    Rails.application.routes.url_helpers.restaurant_path(params[:restaurant])
  end
  
  # Plus nécessaire sans les notifications push
  # def params_with_defaults
  #   super.merge(
  #     title: "Nouveau restaurant ajouté",
  #     body: message,
  #     url: Rails.application.routes.url_helpers.restaurant_url(params[:restaurant])
  #   )
  # end
end

