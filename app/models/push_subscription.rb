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
  rescue WebPush::InvalidSubscription, WebPush::ExpiredSubscription
    # Si l'abonnement est invalide ou expiré, on le supprime
    destroy
  end
end
