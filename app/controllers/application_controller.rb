class ApplicationController < ActionController::Base
    before_action :set_pending_friend_requests
    before_action :set_unread_notifications_count

    private

    def set_pending_friend_requests
        if current_user
          pending_requests = Friendship.where(friend: current_user, status: :pending)
        #   Rails.logger.debug "Pending friend requests count: #{pending_requests.count}, requests: #{pending_requests.inspect}"
          @pending_friend_requests = pending_requests.count
        end
      end

    def set_unread_notifications_count
        if current_user
          @unread_notifications_count = current_user.unread_notifications_count
        end
      end
  end
