class HomeController < ApplicationController
  def index
    if user_signed_in?
      @user = current_user
      @welcome_message = "Bienvenue sur Yum List #{current_user.email} 😋 !"
    else
      @welcome_message = "Bienvenue sur Yum List 😋 !"
    end
  end
end
