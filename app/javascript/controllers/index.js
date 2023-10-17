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



// function attachMenuEventHandlers() {
//   const openMenuButton = document.getElementById("open-menu-button");
//   const closeMenuButton = document.getElementById("close-menu-button");
//   const sideMenu = document.querySelector('.side-menu');
//   openMenuButton.addEventListener("click", () => {
//     console.log("click");
//     if (sideMenu.classList.contains("hidden")) {
//       sideMenu.classList.remove("hidden");
//     }
//     else {
//       sideMenu.classList.add("hidden");
//     }
//   });

//   closeMenuButton.addEventListener("click", () => {
//     if (sideMenu.classList.contains("hidden")) {
//       sideMenu.classList.remove("hidden");
//     }
//     else {
//       sideMenu.classList.add("hidden");
//     }
//   });
// }

// attachMenuEventHandlers();

function openMenu() {
  const sideMenu = document.querySelector('.side-menu');
  sideMenu.classList.remove("hidden");
}

document.addEventListener("DOMContentLoaded", () => {
  const openMenuButton = document.getElementById("open-menu-button");

  if (openMenuButton) {
    openMenuButton.addEventListener("click", openMenu);
  }
});


function closeMenu() {
  const sideMenu = document.querySelector('.side-menu');
  sideMenu.classList.add("hidden");
}

document.addEventListener("DOMContentLoaded", () => {
  const closeMenuButton = document.getElementById("close-menu-button");

  if (closeMenuButton) {
    closeMenuButton.addEventListener("click", closeMenu);
  }
});


// Initialize and add the map
let map;
let userLocation;

async function initMap() {

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

    });
  }
}

document.addEventListener("turbolinks:load", () => {
  initMap();
});
