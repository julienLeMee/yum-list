class HomeController < ApplicationController
  def index
    if user_signed_in?
      @user = current_user
      email = current_user.email
      match = email.match(/(.*)@/)
      if match
        username = match[1]
        @welcome_message = "Welcome to Yum List, #{username}! 😋"
      else
        @welcome_message = "Welcome to Yum List, #{email}! 😋"
      end
    else
      @welcome_message = "Welcome to Yum List 😋 !"
    end

    @restaurants = Restaurant.all
  end
end
