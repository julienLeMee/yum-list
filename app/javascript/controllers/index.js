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
