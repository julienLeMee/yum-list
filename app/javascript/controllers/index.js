// Import and register all your controllers from the importmap under controllers/*
import { application } from "controllers/application"
import './google_places_autocomplete';

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


  document.addEventListener('DOMContentLoaded', function() {
    const accordeon = document.getElementById('accordeon');
    const openingHoursList = document.getElementById('opening-hours-list');

    // Ajout de l'événement 'click' sur l'accordéon
    accordeon.addEventListener('click', activeAccordeon);

    function activeAccordeon() {
      // Vérifie si la liste des horaires est visible ou non
      if (openingHoursList.style.display === 'none') {
        openingHoursList.style.display = 'block'; // Affiche la liste
      } else {
        openingHoursList.style.display = 'none'; // Cache la liste
      }
    }
  });
