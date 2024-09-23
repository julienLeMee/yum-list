class ApplicationController < ActionController::Base
    before_action :set_pending_friend_requests

    private

    def set_pending_friend_requests
        if current_user
          pending_requests = Friendship.where(friend: current_user, status: :pending)
          Rails.logger.debug "Pending friend requests count: #{pending_requests.count}, requests: #{pending_requests.inspect}"
          @pending_friend_requests = pending_requests.count
        end
      end
  end
