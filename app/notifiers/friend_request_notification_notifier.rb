# To deliver this notification:
#
# FriendRequestNotificationNotifier.with(record: @post, message: "New post").deliver(User.all)

class FriendRequestNotificationNotifier < ApplicationNotifier
  # Add your delivery methods
  #
  # deliver_by :email do |config|
  #   config.mailer = "UserMailer"
  #   config.method = "new_post"
  # end
  #
  # bulk_deliver_by :slack do |config|
  #   config.url = -> { Rails.application.credentials.slack_webhook_url }
  # end
  #
  # deliver_by :custom do |config|
  #   config.class = "MyDeliveryMethod"
  # end

  # Add required params
  #
  # required_param :message
  deliver_by :database
  
  # Désactivé temporairement - notifications push
  # deliver_by :custom, class: "WebPushChannel" do |config|
  #   config.enqueue = false
  # end

  def message
    sender_name = params[:sender].email
    "#{sender_name} vous a envoyé une demande d'ami"
  end
  
  # Plus nécessaire sans les notifications push
  # def params_with_defaults
  #   super.merge(
  #     title: "Nouvelle demande d'ami",
  #     body: message,
  #     url: Rails.application.routes.url_helpers.pending_requests_friendships_url
  #   )
  # end
end
