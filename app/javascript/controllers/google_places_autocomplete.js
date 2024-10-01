document.addEventListener("turbo:load", function () {
    initializeAutocomplete('name-autocomplete', 'autocomplete', true); // pour la vue new
    initializeAutocomplete('name-edit-autocomplete', 'address-edit-autocomplete', false); // pour la vue edit
});

function initializeAutocomplete(nameInputId, addressInputId, isNew) {
    const nameInput = document.getElementById(nameInputId);
    const addressInput = document.getElementById(addressInputId);

    if (nameInput) {
        const options = {
            bounds: new google.maps.LatLngBounds(
                new google.maps.LatLng(45.4215, -73.5673),
                new google.maps.LatLng(45.6215, -73.3673)
            ),
            componentRestrictions: { 'country': ['ca'] },
            fields: ['address_components', 'geometry', 'name'],
            strictBounds: false
        };

        const autocompleteName = new google.maps.places.Autocomplete(nameInput, options);

        autocompleteName.addListener('place_changed', function () {
            const place = autocompleteName.getPlace();
            if (!place.geometry) {
                console.log("No details available for input: '" + place.name + "'");
                return;
            }

            nameInput.value = place.name;
            let streetNumber = '';
            let streetName = '';
            let city = '';
            let province = '';
            let postalCode = '';
            let streetSuffix = '';

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
                    province = component.short_name;
                }
                if (component.types.includes('postal_code')) {
                    postalCode = component.long_name;
                }
                if (component.types.includes('sublocality') || component.types.includes('neighborhood')) {
                    streetSuffix = component.long_name;
                }
            });

            const formattedAddress = `${streetNumber} ${streetName} ${streetSuffix}, ${city}, ${province} ${postalCode}`;
            addressInput.value = formattedAddress.trim();
        });
    }
}
