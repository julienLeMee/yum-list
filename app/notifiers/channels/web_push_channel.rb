module Notifiers
  module Channels
    class WebPushChannel
      # Canal personnalisé pour envoyer des notifications push Web
      
      def deliver
        # Récupérer tous les abonnements push de l'utilisateur
        recipient.push_subscriptions.find_each do |subscription|
          begin
            # Envoyer la notification push
            subscription.send_notification(
              title: notification_title,
              body: notification_body,
              url: notification_url
            )
          rescue => e
            # Logger l'erreur mais continuer avec les autres abonnements
            Rails.logger.error("Erreur lors de l'envoi de la notification push: #{e.message}")
          end
        end
      end

      private

      # Ces méthodes sont fournies par Noticed
      # recipient, params sont disponibles automatiquement
      
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
  end
end

