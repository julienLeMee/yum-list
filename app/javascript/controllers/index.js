// Import and register all your controllers from the importmap under controllers/*

import { application } from "controllers/application"

// Eager load all controllers defined in the import map under controllers/**/*_controller
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"
eagerLoadControllersFrom("controllers", application)

// Lazy load controllers as they appear in the DOM (remember not to preload controllers in import map!)
// import { lazyLoadControllersFrom } from "@hotwired/stimulus-loading"
// lazyLoadControllersFrom("controllers", application)


// document.addEventListener('DOMContentLoaded', function () {
//   // Récupérez la case à cocher et la div du rating
//   const testedCheckbox = document.getElementById('tested_checkbox');
//   const ratingDiv = document.getElementById('ratingDiv');

//   // Fonction pour mettre à jour la visibilité de la div en fonction de l'état de la case à cocher
//   function updateRatingVisibility() {
//     ratingDiv.style.visibility = testedCheckbox.checked ? 'visible' : 'hidden';
//   }

//   // Ajoutez un écouteur d'événements pour mettre à jour la visibilité lorsqu'il y a un changement dans la case à cocher
//   testedCheckbox.addEventListener('change', updateRatingVisibility);

//   // Appelez la fonction une fois pour garantir que la visibilité est correcte au chargement de la page
//   updateRatingVisibility();
// });

// document.addEventListener("DOMContentLoaded", function() {
//     // Sélectionner tous les éléments SVG dans les cartes
//     const svgElements = document.querySelectorAll('.restaurant__card svg');

//     svgElements.forEach(svg => {
//         // Générer un angle aléatoire entre 0 et 360 degrés
//         const randomHue = Math.floor(Math.random() * 360);

//         // Appliquer le filtre hue-rotate avec cet angle
//         svg.style.filter = `hue-rotate(${randomHue}deg)`;
//     });
// });

document.addEventListener('DOMContentLoaded', function() {
    // Sélectionnez tous les liens d'ancre
    const anchorLinks = document.querySelectorAll('a[href^="#"]');

    anchorLinks.forEach(link => {
      link.addEventListener('click', function(e) {
        // Empêche le comportement par défaut
        e.preventDefault();

        // Récupère la cible de l'ancre
        const targetId = this.getAttribute('href').substring(1);
        const targetElement = document.getElementById(targetId);

        if (targetElement) {
          // Calcule la position avec un décalage (ajuster l'offset ici)
          const offset = 100; // Décalage en pixels
          const targetPosition = targetElement.getBoundingClientRect().top + window.scrollY - offset;

          // Défilement en douceur vers la position ajustée
          window.scrollTo({
            top: targetPosition,
            behavior: 'smooth'
          });
        }
      });
    });
  });


// Initialize and add the map
// let map;
// let userLocation;

// async function initMap() {
//   // Request needed libraries.
//   //@ts-ignore
//   const { Map } = await google.maps.importLibrary("maps");
//   const { Marker } = await google.maps.importLibrary("marker");
//   const geocoder = new google.maps.Geocoder();

//   // Obtenir la géolocalisation de l'utilisateur
//   if (navigator.geolocation) {
//     navigator.geolocation.getCurrentPosition((position) => {
//       userLocation = {
//         lat: position.coords.latitude,
//         lng: position.coords.longitude,
//       };

//       // Créez la carte centrée sur la géolocalisation de l'utilisateur
//       map = new Map(document.getElementById("map"), {
//         zoom: 15, // Niveau de zoom initial
//         center: userLocation, // Centrez la carte sur la géolocalisation de l'utilisateur
//       });

//       // Créez un marqueur pour la position de l'utilisateur
//       const userMarker = new Marker({
//         map: map,
//         position: userLocation,
//         title: "Votre position actuelle",
//       });

// // Utilisez AJAX pour récupérer la liste de restaurants depuis votre contrôleur
// $.ajax({
//   url: "/restaurant_list", // Utilisez le chemin d'accès de votre route
//   method: "GET",
//   dataType: "json",
//   success: function (data) {
//     const restaurants = data.restaurants;

//     // Parcourez la liste de restaurants récupérée depuis le contrôleur
//     restaurants.forEach(function (restaurant) {
//       geocoder.geocode(
//         { address: restaurant.address },
//         (results, status) => {
//           if (status === "OK" && results[0].geometry) {
//             const restaurantLocation = results[0].geometry.location;

//             // Créez un marqueur pour le restaurant avec ses informations
//             new Marker({
//               map: map,
//               position: restaurantLocation,
//               title: restaurant.name,
//               label: restaurant.name, // Affichez le nom du restaurant au-dessus du marqueur
//             });
//           }
//         }
//       );
//     });
//   },
// });

//     });
//   }
// }

// window.addEventListener("load", () => {
//   initMap();
// });
