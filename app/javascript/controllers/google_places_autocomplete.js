document.addEventListener("turbo:load", function () {
    initializeAutocomplete('name-autocomplete', 'autocomplete', true); // pour la vue new
    initializeAutocomplete('name-edit-autocomplete', 'address-edit-autocomplete', false); // pour la vue edit

    initMap();

    // Accordéons
    const accordeon = document.getElementById('accordeon');
    const openingHoursList = document.getElementById('opening-hours-list');
    const accordionIcon = document.getElementById('accordion-icon');

    accordeon.addEventListener('click', function() {
        if (openingHoursList.style.opacity === '0' || openingHoursList.style.maxHeight === '0px') {
            openingHoursList.style.opacity = '1'; // Affiche la liste
            openingHoursList.style.maxHeight = openingHoursList.scrollHeight + 'px';
            accordionIcon.style.transform = 'rotate(180deg)';
        } else {
            openingHoursList.style.opacity = '0';
            openingHoursList.style.maxHeight = '0px';
            accordionIcon.style.transform = 'rotate(0deg)';
        }
    });

});

function initializeAutocomplete(nameInputId, addressInputId, isNew) {
    const nameInput = document.getElementById(nameInputId);
    const addressInput = document.getElementById(addressInputId);
    const placeIdInput = document.getElementById('place-id-input');

    if (nameInput) {
        const options = {
            bounds: new google.maps.LatLngBounds(
                new google.maps.LatLng(45.4215, -73.5673),
                new google.maps.LatLng(45.6215, -73.3673)
            ),
            fields: ['address_components', 'geometry', 'name', 'place_id'],
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

            const latitude = place.geometry.location.lat();
            const longitude = place.geometry.location.lng();

            const latitudeInput = document.getElementById('latitude-input');
            const longitudeInput = document.getElementById('longitude-input');

            if (latitudeInput) {
                latitudeInput.value = latitude;
            }
            if (longitudeInput) {
                longitudeInput.value = longitude;
            }

            let streetNumber = '';
            let streetName = '';
            let city = '';
            let province = '';
            let postalCode = '';

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
            });

            const formattedAddress = `${streetNumber} ${streetName} \n${city}, ${province} ${postalCode}`;
            addressInput.value = formattedAddress.trim();

            if (placeIdInput) {
                placeIdInput.value = place.place_id;
            }
        });
    }
}

function initMap() {
    const mapDiv = document.getElementById("map");
    if (!mapDiv) {
        console.error("L'élément de la carte n'a pas été trouvé.");
        return;
    }

    const mapOptions = {
        zoom: 12, // Zoom par défaut au cas où il n'y aurait aucun marqueur
        center: { lat: 45.5017, lng: -73.5673 }, // Centre par défaut
        disableDefaultUI: true,
        styles: [
            {
                "featureType": "poi",
                "stylers": [{ "visibility": "off" }]
            }
        ]
    };

    const map = new google.maps.Map(mapDiv, mapOptions);
    const transitLayer = new google.maps.TransitLayer();
    transitLayer.setMap(map);

    fetch('/restaurant_list')
        .then(response => {
            if (!response.ok) {
                throw new Error(`HTTP error! status: ${response.status}`);
            }
            const contentType = response.headers.get("content-type");
            if (!contentType || !contentType.includes("application/json")) {
                throw new TypeError("Oops, we haven't got JSON!");
            }
            return response.json();
        })
        .then(data => {
            console.log('Data received:', data);

            const markers = [];
            const bounds = new google.maps.LatLngBounds();

            data.restaurants.forEach(restaurant => {
                if (restaurant.latitude && restaurant.longitude) {
                    const position = { lat: restaurant.latitude, lng: restaurant.longitude };
                    const path = "M20 10C20 14.4183 12 22 12 22C12 22 4 14.4183 4 10C4 5.58172 7.58172 2 12 2C16.4183 2 20 5.58172 20 10Z M12 11C12.5523 11 13 10.5523 13 10C13 9.44772 12.5523 9 12 9C11.4477 9 11 9.44772 11 10C11 10.5523 11.4477 11 12 11Z";

                    const marker = new google.maps.Marker({
                        position: position,
                        title: restaurant.name,
                        icon: {
                            path: path,
                            fillColor: "#b1454a",
                            fillOpacity: 1,
                            strokeColor: "#f4858a",
                            strokeWeight: 0,
                            rotation: 0,
                            scale: 2,
                            anchor: new google.maps.Point(12, 22),
                        }
                    });

                    markers.push(marker);

                    const infowindow = new google.maps.InfoWindow({
                        content: `<h3 class='font-semibold mb-2'>${restaurant.name}</h3><p>${restaurant.category}</p>`,
                    });

                    marker.addListener('click', () => {
                        infowindow.open(map, marker);
                    });

                    // Ajoutez la position du marqueur aux limites
                    bounds.extend(position);
                } else {
                    console.warn(`Restaurant ${restaurant.name} n'a pas de coordonnées valides.`);
                }
            });

            // Ajustez la carte pour inclure tous les marqueurs
            if (!bounds.isEmpty()) {
                map.fitBounds(bounds);
            }

            // Créer un cluster avec les marqueurs
            const markerCluster = new MarkerClusterer(map, markers, {
                styles: [{
                    textColor: '#ffffff',
                    url: createClusterImageUrl('#b1454a', 30),
                    height: 30,
                    width: 30
                }],
                maxZoom: 15,
                gridSize: 30
            });
        })
        .catch(error => {
            console.error('Error fetching restaurant data:', error);
        });

    function createClusterImageUrl(color, size) {
        const canvas = document.createElement('canvas');
        canvas.width = size;
        canvas.height = size;

        const ctx = canvas.getContext('2d');
        ctx.fillStyle = color;
        ctx.beginPath();
        ctx.arc(size / 2, size / 2, size / 2, 0, Math.PI * 2);
        ctx.fill();

        return canvas.toDataURL();
    }
}

document.addEventListener("turbo:load", function () {
    // Couleur aléatoire pour les SVG dans les cartes restaurants
    function getRandomColor() {
        const letters = '0123456789ABCDEF';
        let color = '#';
        for (let i = 0; i < 6; i++) {
            color += letters[Math.floor(Math.random() * 16)];
        }
        return color;
    }

    const svgElements = document.querySelectorAll('.restaurant__card svg');

    svgElements.forEach(svg => {
        const randomColor = getRandomColor();

        svg.style.color = randomColor;
    });

    const categoriesCards = document.querySelectorAll('.categories__cards');
    categoriesCards.forEach(card => {
        const randomColor = getRandomColor();

        card.style.backgroundColor = randomColor;
    });
})
