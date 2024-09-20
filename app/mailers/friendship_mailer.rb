class FriendshipMailer < ApplicationMailer
    default from: 'pepperwoood@gmail.com'

    def friend_request_email(user, friend)
      @user = user
      @friend = friend
      mail(to: @friend.email, subject: 'You have a new friend request!')
    end
  end
