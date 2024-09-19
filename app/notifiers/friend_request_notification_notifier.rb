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

  def message
    "#{params[:sender].email} sent you a friend request."
  end
end
