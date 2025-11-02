class PushSubscription < ApplicationRecord
  belongs_to :user
  
  validates :endpoint, presence: true, uniqueness: { scope: :user_id }
  validates :p256dh, presence: true
  validates :auth, presence: true
  
  # Méthode pour envoyer une notification push
  def send_notification(title:, body:, url: nil)
    message = {
      title: title,
      body: body,
      url: url || Rails.application.routes.url_helpers.root_url,
      icon: '/yum-list-logo.png',
      badge: '/yum-list-logo.png'
    }
    
    Rails.logger.info("[PushSubscription] Envoi push: title=#{title}, body=#{body}, url=#{url}")
    
    WebPush.payload_send(
      message: message.to_json,
      endpoint: endpoint,
      p256dh: p256dh,
      auth: auth,
      vapid: {
        subject: "mailto:#{ENV['VAPID_EMAIL']}",
        public_key: ENV['VAPID_PUBLIC_KEY'],
        private_key: ENV['VAPID_PRIVATE_KEY']
      }
    )
    
    Rails.logger.info("[PushSubscription] Push envoyé avec succès")
  rescue WebPush::InvalidSubscription => e
    Rails.logger.error("[PushSubscription] Abonnement invalide, suppression: #{e.message}")
    destroy
    raise # Re-raise pour que WebPushChannel le logge aussi
  rescue WebPush::ExpiredSubscription => e
    Rails.logger.error("[PushSubscription] Abonnement expiré, suppression: #{e.message}")
    destroy
    raise # Re-raise pour que WebPushChannel le logge aussi
  rescue => e
    Rails.logger.error("[PushSubscription] Erreur inattendue lors de l'envoi: #{e.class.name} - #{e.message}")
    raise # Re-raise pour que WebPushChannel le logge aussi
  end
end
