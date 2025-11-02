class WebPushChannel < Noticed::DeliveryMethod
  # Canal personnalisé pour envoyer des notifications push Web
  
  def deliver
    # Récupérer tous les abonnements push de l'utilisateur
    subscription_count = recipient.push_subscriptions.count
    Rails.logger.info("[WebPushChannel] Tentative d'envoi pour user ##{recipient.id}, #{subscription_count} abonnement(s) trouvé(s)")
    
    if subscription_count == 0
      Rails.logger.warn("[WebPushChannel] Aucun abonnement push pour user ##{recipient.id} - notification non envoyée")
      return
    end
    
    recipient.push_subscriptions.find_each do |subscription|
      begin
        Rails.logger.info("[WebPushChannel] Envoi de la notification push à l'endpoint: #{subscription.endpoint[0..50]}...")
        # Envoyer la notification push
        subscription.send_notification(
          title: notification_title,
          body: notification_body,
          url: notification_url
        )
        Rails.logger.info("[WebPushChannel] Notification push envoyée avec succès")
      rescue => e
        # Logger l'erreur mais continuer avec les autres abonnements
        Rails.logger.error("[WebPushChannel] Erreur lors de l'envoi de la notification push: #{e.class.name} - #{e.message}")
        Rails.logger.error("[WebPushChannel] Backtrace: #{e.backtrace.first(5).join("\n")}")
      end
    end
  end

  private
  
  def notification_title
    # Titre par défaut, peut être personnalisé par chaque notifier
    params[:title] || "Yum List"
  end

  def notification_body
    # Corps par défaut, peut être personnalisé par chaque notifier
    params[:body] || "Vous avez une nouvelle notification"
  end

  def notification_url
    # URL par défaut, peut être personnalisée par chaque notifier
    params[:url] || Rails.application.routes.url_helpers.notifications_url
  end
end

