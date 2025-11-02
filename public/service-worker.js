// Installation du Service Worker
self.addEventListener('install', function(event) {
  event.waitUntil(
    caches.open('v1').then(function(cache) {
      return cache.addAll([
        '/',
        '/manifest.json',
        '/stylesheets/application.css',
        '/javascript/application.js'
      ]);
    })
  );
  // Active immédiatement le nouveau service worker
  self.skipWaiting();
});

// Activation du Service Worker
self.addEventListener('activate', function(event) {
  event.waitUntil(
    // Nettoyer les anciens caches si nécessaire
    caches.keys().then(function(cacheNames) {
      return Promise.all(
        cacheNames.filter(function(cacheName) {
          return cacheName !== 'v1';
        }).map(function(cacheName) {
          return caches.delete(cacheName);
        })
      );
    })
  );
  // Prendre le contrôle de tous les clients immédiatement
  return self.clients.claim();
});

// Gestion des requêtes
self.addEventListener('fetch', function(event) {
  event.respondWith(
    caches.match(event.request).then(function(response) {
      return response || fetch(event.request);
    })
  );
});

// Réception des notifications push
self.addEventListener('push', function(event) {
  console.log('Push reçu:', event);
  
  let notificationData = {
    title: 'Yum List',
    body: 'Vous avez une nouvelle notification',
    icon: '/yum-list-logo.png',
    badge: '/yum-list-logo.png',
    data: {
      url: '/'
    }
  };

  // Si le push contient des données, les parser
  if (event.data) {
    try {
      const data = event.data.json();
      notificationData = {
        title: data.title || notificationData.title,
        body: data.body || notificationData.body,
        icon: data.icon || notificationData.icon,
        badge: data.badge || notificationData.badge,
        data: {
          url: data.url || notificationData.data.url
        }
      };
    } catch (e) {
      console.error('Erreur lors du parsing des données push:', e);
    }
  }

  event.waitUntil(
    self.registration.showNotification(notificationData.title, {
      body: notificationData.body,
      icon: notificationData.icon,
      badge: notificationData.badge,
      data: notificationData.data,
      vibrate: [200, 100, 200],
      tag: 'yum-list-notification',
      renotify: true
    })
  );
});

// Gestion du clic sur la notification
self.addEventListener('notificationclick', function(event) {
  console.log('Notification cliquée:', event);
  event.notification.close();

  // Ouvrir ou focus sur l'URL spécifiée
  const urlToOpen = event.notification.data.url || '/';
  
  event.waitUntil(
    clients.matchAll({
      type: 'window',
      includeUncontrolled: true
    }).then(function(clientList) {
      // Si une fenêtre est déjà ouverte, la focus
      for (let i = 0; i < clientList.length; i++) {
        const client = clientList[i];
        if (client.url === urlToOpen && 'focus' in client) {
          return client.focus();
        }
      }
      // Sinon, ouvrir une nouvelle fenêtre
      if (clients.openWindow) {
        return clients.openWindow(urlToOpen);
      }
    })
  );
});
