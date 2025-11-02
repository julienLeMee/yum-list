import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="push-notifications"
export default class extends Controller {
  static targets = ["button", "status"]
  
  async connect() {
    console.log("Push notifications controller connecté")
    const supported = await this.checkPushSupport()
    if (supported) {
      // Attendre que le service worker soit enregistré
      await this.waitForServiceWorker()
      await this.updateUI()
    }
  }

  async waitForServiceWorker() {
    if (!('serviceWorker' in navigator)) {
      return false
    }

    try {
      // Attendre que le service worker soit enregistré
      let registration = await navigator.serviceWorker.getRegistration()
      
      if (!registration) {
        console.log('Service Worker pas encore enregistré, attente...')
        // Attendre un peu et réessayer
        await new Promise(resolve => setTimeout(resolve, 1000))
        registration = await navigator.serviceWorker.getRegistration()
      }

      if (registration) {
        console.log('Service Worker trouvé:', registration.scope)
        // Attendre que le service worker soit activé
        await navigator.serviceWorker.ready
        console.log('Service Worker prêt!')
        return true
      }

      return false
    } catch (error) {
      console.error('Erreur lors de l\'attente du Service Worker:', error)
      return false
    }
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
    if (!supported) {
      this.showError('Les notifications push ne sont pas supportées sur cet appareil/navigateur.')
      return
    }

    // S'assurer que le service worker est prêt
    const swReady = await this.waitForServiceWorker()
    if (!swReady) {
      this.showError('Le service worker n\'est pas prêt. Veuillez rafraîchir la page et réessayer.')
      return
    }

    try {
      const registration = await navigator.serviceWorker.ready
      console.log('Service Worker ready, vérification de l\'abonnement...')
      const existingSubscription = await registration.pushManager.getSubscription()

      if (existingSubscription) {
        console.log('Abonnement existant trouvé, désabonnement...')
        // Désabonner
        await this.unsubscribe(existingSubscription)
      } else {
        console.log('Aucun abonnement, création d\'un nouvel abonnement...')
        // S'abonner
        await this.subscribe(registration)
      }

      await this.updateUI()
    } catch (error) {
      console.error('Erreur lors du toggle des notifications:', error)
      this.showError(`Une erreur est survenue: ${error.message}. Veuillez réessayer.`)
    }
  }

  async subscribe(registration) {
    try {
      console.log('Début de l\'abonnement aux notifications push...')
      
      // Vérifier que nous sommes en HTTPS ou localhost (requis pour les notifications)
      if (location.protocol !== 'https:' && location.hostname !== 'localhost' && location.hostname !== '127.0.0.1') {
        this.showError('Les notifications push nécessitent HTTPS. Veuillez utiliser l\'application en production.')
        return
      }

      // Demander la permission
      console.log('Demande de permission pour les notifications...')
      const permission = await Notification.requestPermission()
      console.log('Permission:', permission)
      
      if (permission !== 'granted') {
        if (permission === 'denied') {
          this.showError('Permission refusée. Vous devez autoriser les notifications dans les paramètres de votre navigateur.')
        } else {
          this.showError('Permission refusée. Vous devez autoriser les notifications.')
        }
        return
      }

      console.log('Permission accordée! Récupération de la clé VAPID...')
      // Récupérer la clé publique VAPID
      const response = await fetch('/push_subscriptions/vapid_public_key')
      if (!response.ok) {
        throw new Error(`Erreur HTTP ${response.status} lors de la récupération de la clé VAPID`)
      }
      const data = await response.json()
      const vapidPublicKey = data.public_key
      console.log('Clé VAPID récupérée:', vapidPublicKey.substring(0, 20) + '...')

      // Convertir la clé publique en Uint8Array
      const convertedVapidKey = this.urlBase64ToUint8Array(vapidPublicKey)

      console.log('Création de l\'abonnement push...')
      // Créer l'abonnement
      const subscription = await registration.pushManager.subscribe({
        userVisibleOnly: true,
        applicationServerKey: convertedVapidKey
      })
      console.log('Abonnement créé:', subscription.endpoint.substring(0, 50) + '...')

      // Envoyer l'abonnement au serveur
      console.log('Envoi de l\'abonnement au serveur...')
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
        const result = await subscriptionResponse.json()
        console.log('Abonnement enregistré avec succès:', result)
        this.showSuccess('Notifications activées avec succès ! 🎉')
      } else {
        const errorText = await subscriptionResponse.text()
        console.error('Erreur serveur:', errorText)
        throw new Error(`Échec de l'enregistrement: ${subscriptionResponse.status} ${errorText}`)
      }
    } catch (error) {
      console.error('Erreur lors de l\'abonnement:', error)
      this.showError(`Impossible d'activer les notifications: ${error.message}`)
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

