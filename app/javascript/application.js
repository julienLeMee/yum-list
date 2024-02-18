// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"

document.addEventListener("DOMContentLoaded", () => {
  const openMenuButton = document.getElementById("open-menu-button");
  const closeMenuButton = document.getElementById("close-menu-button");
  const sideMenu = document.querySelector('.side-menu');

  if (openMenuButton && closeMenuButton) {
    openMenuButton.addEventListener("click", () => {
      sideMenu.classList.remove("hidden");
    });

    closeMenuButton.addEventListener("click", () => {
      sideMenu.classList.add("hidden");
    });
  }
});


// Initialize and add the map
let map;

async function initMap() {
  // The location of Uluru
  const position = { lat: -25.344, lng: 131.031 };
  // Request needed libraries.
  //@ts-ignore
  const { Map } = await google.maps.importLibrary("maps");
  const { AdvancedMarkerView } = await google.maps.importLibrary("marker");

  // The map, centered at Uluru
  map = new Map(document.getElementById("map"), {
    zoom: 4,
    center: position,
    mapId: "DEMO_MAP_ID",
  });

  // The marker, positioned at Uluru
  const marker = new AdvancedMarkerView({
    map: map,
    position: position,
    title: "Uluru",
  });
}

initMap();
