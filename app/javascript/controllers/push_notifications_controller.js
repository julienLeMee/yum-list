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

  async waitForServiceWorker(maxAttempts = 10, delay = 500) {
    if (!('serviceWorker' in navigator)) {
      console.log('❌ Service Worker non supporté dans ce navigateur')
      return false
    }

    // Vérifier s'il y a une erreur d'enregistrement globale
    if (window.serviceWorkerError) {
      console.error('❌ Erreur d\'enregistrement du Service Worker détectée:', window.serviceWorkerError)
      return false
    }

    // Si window.serviceWorkerReady existe (défini dans le layout), l'utiliser
    if (window.serviceWorkerReady) {
      try {
        await window.serviceWorkerReady
        console.log('✅ Service Worker prêt via window.serviceWorkerReady!')
        return true
      } catch (e) {
        console.warn('⚠️ Erreur avec window.serviceWorkerReady:', e)
        // Continuer avec la méthode normale
      }
    }

    // Si le service worker est déjà prêt, on retourne immédiatement
    try {
      const existingRegistration = await navigator.serviceWorker.getRegistration()
      if (existingRegistration) {
        console.log('📋 Service Worker enregistré trouvé, vérification de l\'état...')
        console.log('📋 État - installing:', existingRegistration.installing?.state)
        console.log('📋 État - waiting:', existingRegistration.waiting?.state)
        console.log('📋 État - active:', existingRegistration.active?.state)
        
        try {
          await navigator.serviceWorker.ready
          console.log('✅ Service Worker déjà prêt!')
          return true
        } catch (e) {
          console.log('⏳ Service Worker enregistré mais pas encore prêt, attente...', e)
        }
      } else {
        console.log('⚠️ Aucun Service Worker enregistré trouvé')
      }
    } catch (e) {
      console.log('⚠️ Erreur lors de la vérification initiale:', e)
    }

    // Sinon, on attend avec plusieurs tentatives
    for (let attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        console.log(`🔄 Tentative ${attempt}/${maxAttempts} pour trouver le Service Worker...`)
        
        // Vérifier si le service worker est maintenant enregistré
        const registration = await navigator.serviceWorker.getRegistration()
        
        if (registration) {
          console.log('✅ Service Worker trouvé:', registration.scope)
          console.log('📋 Détails - installing:', registration.installing?.state, 'waiting:', registration.waiting?.state, 'active:', registration.active?.state)
          
          // Si le service worker est actif, on peut l'utiliser directement
          if (registration.active && registration.active.state === 'activated') {
            console.log('✅ Service Worker déjà activé!')
            return true
          }
          
          // Attendre que le service worker soit activé (ready)
          try {
            // Utiliser Promise.race avec un timeout pour éviter d'attendre indéfiniment
            const readyPromise = navigator.serviceWorker.ready
            const timeoutPromise = new Promise((_, reject) => 
              setTimeout(() => reject(new Error('Timeout')), delay * 2)
            )
            
            await Promise.race([readyPromise, timeoutPromise])
            console.log('✅ Service Worker prêt et activé!')
            return true
          } catch (readyError) {
            if (readyError.message === 'Timeout') {
              console.log(`⏳ Service Worker pas encore ready (timeout après ${delay * 2}ms), tentative ${attempt}/${maxAttempts}...`)
            } else {
              console.log('⏳ Service Worker enregistré mais pas encore ready:', readyError.message)
            }
            // On continue la boucle pour réessayer
          }
        } else {
          console.log(`⚠️ Service Worker pas encore enregistré (tentative ${attempt}/${maxAttempts})`)
          // Vérifier s'il y a une erreur globale
          if (window.serviceWorkerError) {
            console.error('❌ Erreur d\'enregistrement détectée, arrêt des tentatives')
            return false
          }
        }
        
        // Attendre avant la prochaine tentative (sauf si c'était la dernière)
        if (attempt < maxAttempts) {
          await new Promise(resolve => setTimeout(resolve, delay))
        }
      } catch (error) {
        console.error(`❌ Erreur lors de la tentative ${attempt}:`, error)
        if (attempt < maxAttempts) {
          await new Promise(resolve => setTimeout(resolve, delay))
        }
      }
    }

    console.error(`❌ Service Worker non trouvé après ${maxAttempts} tentatives`)
    console.error('💡 Vérifiez la console pour les erreurs d\'enregistrement du Service Worker')
    return false
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

    // Attendre que le service worker soit prêt avant de vérifier l'abonnement
    const swReady = await this.waitForServiceWorker(5, 300) // Moins de tentatives pour updateUI (plus rapide)
    if (!swReady) {
      console.warn('Service Worker pas encore prêt pour updateUI, on réessayera plus tard')
      // Ne pas bloquer, juste mettre le bouton par défaut
      if (this.hasButtonTarget) {
        this.buttonTarget.textContent = '🔕 Activer les notifications'
        this.buttonTarget.classList.remove('bg-green-600', 'hover:bg-green-700')
        this.buttonTarget.classList.add('bg-blue-600', 'hover:bg-blue-700')
      }
      return
    }

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
      // En cas d'erreur, mettre le bouton par défaut
      if (this.hasButtonTarget) {
        this.buttonTarget.textContent = '🔕 Activer les notifications'
        this.buttonTarget.classList.remove('bg-green-600', 'hover:bg-green-700')
        this.buttonTarget.classList.add('bg-blue-600', 'hover:bg-blue-700')
      }
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

