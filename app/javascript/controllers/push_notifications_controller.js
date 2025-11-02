import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="push-notifications"
export default class extends Controller {
  static targets = ["button", "status"]
  
  connect() {
    console.log("Push notifications controller connecté")
    this.checkPushSupport()
    this.updateUI()
  }

  async checkPushSupport() {
    if (!('serviceWorker' in navigator)) {
      console.log('Service Worker non supporté')
      this.disableButton('Service Worker non supporté')
      return false
    }

    if (!('PushManager' in window)) {
      console.log('Push notifications non supportées')
      this.disableButton('Notifications push non supportées')
      return false
    }

    return true
  }

  async updateUI() {
    const supported = await this.checkPushSupport()
    if (!supported) return

    try {
      const registration = await navigator.serviceWorker.ready
      const subscription = await registration.pushManager.getSubscription()
      
      if (this.hasButtonTarget) {
        if (subscription) {
          this.buttonTarget.textContent = '🔔 Notifications activées'
          this.buttonTarget.classList.remove('bg-blue-600', 'hover:bg-blue-700')
          this.buttonTarget.classList.add('bg-green-600', 'hover:bg-green-700')
        } else {
          this.buttonTarget.textContent = '🔕 Activer les notifications'
          this.buttonTarget.classList.remove('bg-green-600', 'hover:bg-green-700')
          this.buttonTarget.classList.add('bg-blue-600', 'hover:bg-blue-700')
        }
      }
    } catch (error) {
      console.error('Erreur lors de la vérification de l\'abonnement:', error)
    }
  }

  async toggleNotifications(event) {
    event.preventDefault()
    
    const supported = await this.checkPushSupport()
    if (!supported) return

    try {
      const registration = await navigator.serviceWorker.ready
      const existingSubscription = await registration.pushManager.getSubscription()

      if (existingSubscription) {
        // Désabonner
        await this.unsubscribe(existingSubscription)
      } else {
        // S'abonner
        await this.subscribe(registration)
      }

      await this.updateUI()
    } catch (error) {
      console.error('Erreur lors du toggle des notifications:', error)
      this.showError('Une erreur est survenue. Veuillez réessayer.')
    }
  }

  async subscribe(registration) {
    try {
      // Demander la permission
      const permission = await Notification.requestPermission()
      
      if (permission !== 'granted') {
        this.showError('Permission refusée. Vous devez autoriser les notifications.')
        return
      }

      // Récupérer la clé publique VAPID
      const response = await fetch('/push_subscriptions/vapid_public_key')
      const data = await response.json()
      const vapidPublicKey = data.public_key

      // Convertir la clé publique en Uint8Array
      const convertedVapidKey = this.urlBase64ToUint8Array(vapidPublicKey)

      // Créer l'abonnement
      const subscription = await registration.pushManager.subscribe({
        userVisibleOnly: true,
        applicationServerKey: convertedVapidKey
      })

      // Envoyer l'abonnement au serveur
      const subscriptionResponse = await fetch('/push_subscriptions', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': this.getCsrfToken()
        },
        body: JSON.stringify({
          subscription: subscription.toJSON()
        })
      })

      if (subscriptionResponse.ok) {
        this.showSuccess('Notifications activées avec succès ! 🎉')
      } else {
        throw new Error('Échec de l\'enregistrement de l\'abonnement')
      }
    } catch (error) {
      console.error('Erreur lors de l\'abonnement:', error)
      this.showError('Impossible d\'activer les notifications.')
      throw error
    }
  }

  async unsubscribe(subscription) {
    try {
      // Désabonner du Push Manager
      await subscription.unsubscribe()

      // Supprimer l'abonnement du serveur
      const response = await fetch('/push_subscriptions', {
        method: 'DELETE',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': this.getCsrfToken()
        },
        body: JSON.stringify({
          endpoint: subscription.endpoint
        })
      })

      if (response.ok) {
        this.showSuccess('Notifications désactivées')
      }
    } catch (error) {
      console.error('Erreur lors du désabonnement:', error)
      this.showError('Impossible de désactiver les notifications.')
      throw error
    }
  }

  // Utilitaires
  urlBase64ToUint8Array(base64String) {
    const padding = '='.repeat((4 - base64String.length % 4) % 4)
    const base64 = (base64String + padding)
      .replace(/\-/g, '+')
      .replace(/_/g, '/')

    const rawData = window.atob(base64)
    const outputArray = new Uint8Array(rawData.length)

    for (let i = 0; i < rawData.length; ++i) {
      outputArray[i] = rawData.charCodeAt(i)
    }
    return outputArray
  }

  getCsrfToken() {
    return document.querySelector('meta[name="csrf-token"]')?.content
  }

  disableButton(message) {
    if (this.hasButtonTarget) {
      this.buttonTarget.disabled = true
      this.buttonTarget.textContent = message
      this.buttonTarget.classList.add('opacity-50', 'cursor-not-allowed')
    }
  }

  showSuccess(message) {
    if (this.hasStatusTarget) {
      this.statusTarget.textContent = message
      this.statusTarget.className = 'mt-2 text-sm text-green-600'
      setTimeout(() => {
        this.statusTarget.textContent = ''
      }, 5000)
    } else {
      console.log(message)
    }
  }

  showError(message) {
    if (this.hasStatusTarget) {
      this.statusTarget.textContent = message
      this.statusTarget.className = 'mt-2 text-sm text-red-600'
      setTimeout(() => {
        this.statusTarget.textContent = ''
      }, 5000)
    } else {
      alert(message)
    }
  }
}

