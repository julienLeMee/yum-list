// Import and register all your controllers from the importmap under controllers/*

import { application } from "controllers/application"

// Eager load all controllers defined in the import map under controllers/**/*_controller
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"
eagerLoadControllersFrom("controllers", application)

// Lazy load controllers as they appear in the DOM (remember not to preload controllers in import map!)
// import { lazyLoadControllersFrom } from "@hotwired/stimulus-loading"
// lazyLoadControllersFrom("controllers", application)

// const tabs = document.querySelectorAll(".group");

// tabs.forEach((tab) => {
//   tab.addEventListener("click", (e) => {
//     tab.classList.add("is-active");
//     e.preventDefault();
//     tabs.forEach((otherTab) => {
//       if (otherTab !== tab) {
//         otherTab.classList.remove("is-active");
//       }
//     });
//   });
// });

const openMenuButton = document.getElementById("open-menu-button");
const closeMenuButton = document.getElementById("close-menu-button");
const sideMenu = document.querySelector('.side-menu'); // Sélectionnez le menu mobile

  openMenuButton.addEventListener("click", () => {
    if (sideMenu.classList.contains("hidden")) {
      sideMenu.classList.remove("hidden");
    } else {
      sideMenu.classList.add("hidden");
    }
  });

  closeMenuButton.addEventListener("click", () => {
    if (sideMenu.classList.contains("hidden")) {
      sideMenu.classList.remove("hidden");
    } else {
      sideMenu.classList.add("hidden");
    }
  });


  const googleMapsApiKey = window.GOOGLE_MAPS_API_KEY;
// Initialize and add the map
let map;
let userLocation;

async function initMap() {
  // Request needed libraries.
  //@ts-ignore
  const { Map } = await google.maps.importLibrary("maps");
  const { Marker } = await google.maps.importLibrary("marker");
  const geocoder = new google.maps.Geocoder();

  // Obtenir la géolocalisation de l'utilisateur
  if (navigator.geolocation) {
    navigator.geolocation.getCurrentPosition((position) => {
      userLocation = {
        lat: position.coords.latitude,
        lng: position.coords.longitude,
      };

      // Créez la carte centrée sur la géolocalisation de l'utilisateur
      map = new Map(document.getElementById("map"), {
        zoom: 15, // Niveau de zoom initial
        center: userLocation, // Centrez la carte sur la géolocalisation de l'utilisateur
      });

      // Créez un marqueur pour la position de l'utilisateur
      const userMarker = new Marker({
        map: map,
        position: userLocation,
        title: "Votre position actuelle",
      });

// Utilisez AJAX pour récupérer la liste de restaurants depuis votre contrôleur
$.ajax({
  url: "/restaurant_list", // Utilisez le chemin d'accès de votre route
  method: "GET",
  dataType: "json",
  success: function (data) {
    const restaurants = data.restaurants;

    // Parcourez la liste de restaurants récupérée depuis le contrôleur
    restaurants.forEach(function (restaurant) {
      geocoder.geocode(
        { address: restaurant.address },
        (results, status) => {
          if (status === "OK" && results[0].geometry) {
            const restaurantLocation = results[0].geometry.location;

            // Créez un marqueur pour le restaurant avec ses informations
            new Marker({
              map: map,
              position: restaurantLocation,
              title: restaurant.name,
              label: restaurant.name, // Affichez le nom du restaurant au-dessus du marqueur
            });
          }
        }
      );
    });
  },
});

    });
  }
}

window.addEventListener("load", () => {
  initMap();
});
