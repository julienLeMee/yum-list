class PushSubscriptionsController < ApplicationController
  before_action :authenticate_user!
  skip_before_action :verify_authenticity_token, only: [:create, :destroy]

  # GET /push_subscriptions/vapid_public_key
  def vapid_public_key
    render json: { public_key: ENV['VAPID_PUBLIC_KEY'] }
  end

  # POST /push_subscriptions
  def create
    subscription = current_user.push_subscriptions.find_or_initialize_by(
      endpoint: subscription_params[:endpoint]
    )
    
    subscription.assign_attributes(
      p256dh: subscription_params[:keys][:p256dh],
      auth: subscription_params[:keys][:auth]
    )

    if subscription.save
      render json: { success: true, message: 'Abonnement créé avec succès' }, status: :created
    else
      render json: { success: false, errors: subscription.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /push_subscriptions
  def destroy
    subscription = current_user.push_subscriptions.find_by(endpoint: params[:endpoint])
    
    if subscription&.destroy
      render json: { success: true, message: 'Abonnement supprimé avec succès' }
    else
      render json: { success: false, message: 'Abonnement non trouvé' }, status: :not_found
    end
  end

  private

  def subscription_params
    params.require(:subscription).permit(:endpoint, keys: [:p256dh, :auth])
  end
end
