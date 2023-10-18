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
