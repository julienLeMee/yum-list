document.addEventListener("turbo:load", function () {
    initializeAutocomplete('name-autocomplete', 'autocomplete', true); // pour la vue new
    initializeAutocomplete('name-edit-autocomplete', 'address-edit-autocomplete', false); // pour la vue edit

    // Appeler initMap ici pour s'assurer que l'élément #map est disponible
    initMap();

    // Accordéons
    const accordeon = document.getElementById('accordeon');
    const openingHoursList = document.getElementById('opening-hours-list');
    const accordionIcon = document.getElementById('accordion-icon');

    // Ajout de l'événement 'click' sur l'accordéon
    accordeon.addEventListener('click', function() {
        // Vérifie si la liste des horaires est visible ou non
        if (openingHoursList.style.opacity === '0' || openingHoursList.style.maxHeight === '0px') {
            openingHoursList.style.opacity = '1'; // Affiche la liste
            openingHoursList.style.maxHeight = openingHoursList.scrollHeight + 'px'; // Ajuste max-height
            accordionIcon.style.transform = 'rotate(180deg)'; // Rotation de l'icône
        } else {
            openingHoursList.style.opacity = '0'; // Cache la liste
            openingHoursList.style.maxHeight = '0px'; // Réinitialise max-height
            accordionIcon.style.transform = 'rotate(0deg)'; // Remet à l'état d'origine
        }
    });

    // Fonction pour créer une image de cluster personnalisée
    function createClusterImageUrl(color, size) {
        const canvas = document.createElement('canvas');
        canvas.width = size;
        canvas.height = size;

        const ctx = canvas.getContext('2d');
        ctx.fillStyle = color;
        ctx.beginPath();
        ctx.arc(size / 2, size / 2, size / 2, 0, Math.PI * 2);
        ctx.fill();

        ctx.fillStyle = '#ffffff'; // Couleur du texte

        return canvas.toDataURL();
    }

});

function initializeAutocomplete(nameInputId, addressInputId, isNew) {
    const nameInput = document.getElementById(nameInputId);
    const addressInput = document.getElementById(addressInputId);
    const placeIdInput = document.getElementById('place-id-input'); // Assurez-vous que cet ID correspond à votre champ caché pour place_id

    if (nameInput) {
        const options = {
            bounds: new google.maps.LatLngBounds(
                new google.maps.LatLng(45.4215, -73.5673),
                new google.maps.LatLng(45.6215, -73.3673)
            ),
            componentRestrictions: { 'country': ['ca'] },
            fields: ['address_components', 'geometry', 'name', 'place_id'], // Vous avez déjà ici le champ place_id
            strictBounds: false
        };

        const autocompleteName = new google.maps.places.Autocomplete(nameInput, options);

        autocompleteName.addListener('place_changed', function () {
            const place = autocompleteName.getPlace();
            console.log('PLAAACE :', place);
            if (!place.geometry) {
                console.log("No details available for input: '" + place.name + "'");
                return;
            }

            nameInput.value = place.name;

            // Récupération des coordonnées
            const latitude = place.geometry.location.lat();
            const longitude = place.geometry.location.lng();

            // Mettez à jour vos champs cachés ou vos variables
            const latitudeInput = document.getElementById('latitude-input'); // Assurez-vous que cet ID correspond à votre champ caché pour latitude
            const longitudeInput = document.getElementById('longitude-input'); // Assurez-vous que cet ID correspond à votre champ caché pour longitude

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
    const mapDiv = document.getElementById("map"); // Assurez-vous que cet ID existe
    if (!mapDiv) {
        console.error("L'élément de la carte n'a pas été trouvé.");
        return; // Sortir si l'élément n'existe pas
    }

    const mapOptions = {
        zoom: 12,
        center: { lat: 45.5017, lng: -73.5673 }, // Coordonnées pour Montréal
        disableDefaultUI: true,
        styles: [ // Ajouter les styles ici
            {
                "featureType": "poi",
                "stylers": [
                    { "visibility": "off" } // Masquer les points d'intérêt
                ]
            }
        ]
    };

    const map = new google.maps.Map(mapDiv, mapOptions); // Passer mapDiv ici

    const transitLayer = new google.maps.TransitLayer();
    transitLayer.setMap(map);

    // Récupérer la liste des restaurants via une requête AJAX
    fetch('/restaurant_list')
        .then(response => {
            if (!response.ok) {
                throw new Error(`HTTP error! status: ${response.status}`);
            }
            const contentType = response.headers.get("content-type");
            if (!contentType || !contentType.includes("application/json")) {
                throw new TypeError("Oops, we haven't got JSON!");
            }
            return response.json(); // Essaie de convertir en JSON
        })
        .then(data => {
            console.log('Data received:', data);

            const markers = []; // Tableau pour stocker les marqueurs

            data.restaurants.forEach(restaurant => {
                if (restaurant.latitude && restaurant.longitude) { // Vérifier la présence de latitude et longitude
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

                    markers.push(marker); // Ajouter le marqueur au tableau

                    // Optionnel : ajouter un événement de clic pour afficher des infos sur le restaurant
                    const infowindow = new google.maps.InfoWindow({
                        content: `<h3 class='font-semibold mb-2'>${restaurant.name}</h3><p>${restaurant.category}</p>`,
                    });

                    marker.addListener('click', () => {
                        infowindow.open(map, marker);
                    });
                } else {
                    console.warn(`Restaurant ${restaurant.name} n'a pas de coordonnées valides.`);
                }
            });

            // Créer un cluster avec les marqueurs
            const markerCluster = new MarkerClusterer(map, markers, {
                styles: [{
                    textColor: '#ffffff', // Couleur du texte
                    url: createClusterImageUrl('#b1454a', 30), // Couleur du cluster
                    height: 30,
                    width: 30
                }],
                maxZoom: 15, // Ajuster le zoom maximal pour le cluster
                gridSize: 30
            });
        })
        .catch(error => {
            console.error('Error fetching restaurant data:', error);
        });
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

    // Sélectionne tous les SVG dans les éléments avec la classe 'restaurant__card'
    const svgElements = document.querySelectorAll('.restaurant__card svg');

    svgElements.forEach(svg => {
        // Générer une couleur aléatoire
        const randomColor = getRandomColor();

        // Appliquer la couleur aléatoire comme couleur de remplissage (fill)
        svg.style.color = randomColor;
    });
})
