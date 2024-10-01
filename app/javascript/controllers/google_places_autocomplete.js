document.addEventListener("DOMContentLoaded", function () {
    const nameInputEdit = document.getElementById('name-edit-autocomplete');
    const addressInputEdit = document.getElementById('address-edit-autocomplete');

    if (nameInputEdit) {
      const options = {
        // Prioriser les réponses autour de Montréal
        bounds: new google.maps.LatLngBounds(
          new google.maps.LatLng(45.4215, -73.5673),  // Coordonnées approximatives de Montréal
          new google.maps.LatLng(45.6215, -73.3673)
        ),
        componentRestrictions: { 'country': ['ca'] },  // Restriction au Canada
        fields: ['address_components', 'geometry', 'name'],  // Champs à retourner
        strictBounds: false  // Recherche peut sortir des bounds, mais priorise les résultats à l'intérieur
      };

      // Initialiser l'API Places pour le champ "Name" dans la vue edit
      const autocompleteNameEdit = new google.maps.places.Autocomplete(nameInputEdit, options);

      // Ajoutez un écouteur d'événement pour capturer les détails du lieu une fois sélectionné
      autocompleteNameEdit.addListener('place_changed', function () {
        const place = autocompleteNameEdit.getPlace();

        if (!place.geometry) {
          console.log("No details available for input: '" + place.name + "'");
          return;
        }

        // Remplir le champ "Name" uniquement avec le nom du lieu
        nameInputEdit.value = place.name;

        // Récupérer et structurer l'adresse
        let streetNumber = '';
        let streetName = '';
        let city = '';
        let province = '';
        let postalCode = '';
        let streetSuffix = ''; // ex: 'Est' ou 'Ouest'

        place.address_components.forEach(component => {
          if (component.types.includes('street_number')) {
            streetNumber = component.long_name;
          }
          if (component.types.includes('route')) {
            streetName = component.short_name;
          }
          if (component.types.includes('locality')) {
            city = component.long_name;
          }
          if (component.types.includes('administrative_area_level_1')) {
            province = component.short_name; // QC pour Quebec
          }
          if (component.types.includes('postal_code')) {
            postalCode = component.long_name;
          }
          if (component.types.includes('sublocality') || component.types.includes('neighborhood')) {
            streetSuffix = component.long_name;
          }
        });

        // Construire l'adresse formatée
        const formattedAddress = `${streetNumber} ${streetName} ${streetSuffix}, ${city}, ${province} ${postalCode}`;

        // Remplir automatiquement le champ "Address" avec l'adresse formatée
        addressInputEdit.value = formattedAddress.trim();
      });
    }
  });
