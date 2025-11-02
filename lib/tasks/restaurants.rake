namespace :restaurants do
  desc "Update place_id and fetch images for all restaurants"
  task fetch_images: :environment do
    puts "Updating place_id and fetching images for all restaurants..."
    
    Restaurant.find_each do |restaurant|
      puts "Processing #{restaurant.name} (ID: #{restaurant.id})..."
      
      if restaurant.place_id.present? && 
         restaurant.place_id != "id place-id-input" && 
         !restaurant.place_id.start_with?("id ")
        # Si place_id valide mais pas d'image, juste récupérer l'image
        if restaurant.image_url.blank?
          FetchRestaurantImageJob.perform_now(restaurant.id)
          restaurant.reload
          puts "  #{restaurant.image_url.present? ? '✓' : '✗'} Image: #{restaurant.image_url.present? ? 'fetched' : 'failed'}"
        else
          puts "  ✓ Already has image"
        end
      else
        # Si pas de place_id valide, chercher et mettre à jour
        puts "  Searching for place_id..."
        FetchAndUpdateRestaurantPlaceIdJob.perform_now(restaurant.id)
        restaurant.reload
        
        if restaurant.place_id.present? && 
           restaurant.place_id != "id place-id-input" && 
           !restaurant.place_id.start_with?("id ")
          puts "  ✓ Place ID found: #{restaurant.place_id[0..30]}..."
          puts "  #{restaurant.image_url.present? ? '✓' : '✗'} Image: #{restaurant.image_url.present? ? 'fetched' : 'failed'}"
        else
          puts "  ✗ Could not find place_id"
          puts "    ⚠️  Check logs for details. Possible reasons:"
          puts "       - API key has referer restrictions (needs server key without restrictions)"
          puts "       - Restaurant not found in Google Places"
          puts "       - See README_IMAGES.md for configuration help"
        end
      end
      
      sleep 0.5 # Rate limiting pour Google API
    end
    
    puts "\nDone!"
  end
  
  desc "Fetch images for restaurants with valid place_id (old method)"
  task fetch_images_old: :environment do
    puts "Fetching images for restaurants..."
    
    # Trouver tous les restaurants avec un place_id valide (même s'ils ont déjà une image)
    restaurants = Restaurant.where.not(place_id: nil)
                             .where('place_id != ?', 'id place-id-input')
                             .where.not('place_id LIKE ?', 'id %')
    
    puts "Found #{restaurants.count} restaurants with valid place_id"
    
    restaurants_without_images = restaurants.where(image_url: nil)
    puts "  - #{restaurants_without_images.count} without images"
    puts "  - #{restaurants.count - restaurants_without_images.count} already have images"
    
    # Traiter ceux sans images
    restaurants_without_images.find_each do |restaurant|
      puts "Processing #{restaurant.name} (ID: #{restaurant.id}, Place ID: #{restaurant.place_id})..."
      begin
        FetchRestaurantImageJob.perform_now(restaurant.id)
        restaurant.reload
        if restaurant.image_url.present?
          puts "  ✓ Image fetched: #{restaurant.image_url[0..50]}..."
        else
          puts "  ✗ Failed to fetch image"
        end
      rescue => e
        puts "  ✗ Error: #{e.message}"
      end
      sleep 0.5 # Rate limiting
    end
    
    puts "\nDone!"
  end
  
  desc "List all restaurants and their place_id status"
  task list: :environment do
    puts "All restaurants:\n"
    Restaurant.all.each do |r|
      valid = r.place_id.present? && r.place_id != 'id place-id-input' && !r.place_id.start_with?('id ')
      status = valid ? '✓ VALID' : '✗ INVALID'
      image_status = r.image_url.present? ? '✓' : '✗'
      puts "#{r.id.to_s.rjust(3)} | #{status.ljust(10)} | #{image_status} | #{r.name.ljust(30)} | #{r.place_id || 'nil'}"
    end
    puts "\nSummary:"
    puts "  Total: #{Restaurant.count}"
    puts "  With valid place_id: #{Restaurant.where.not(place_id: nil).where('place_id != ?', 'id place-id-input').where.not('place_id LIKE ?', 'id %').count}"
    puts "  With images: #{Restaurant.where.not(image_url: nil).count}"
  end
  
  desc "Test image fetch for a specific restaurant"
  task :test_image, [:restaurant_id] => :environment do |t, args|
    restaurant = Restaurant.find(args[:restaurant_id])
    puts "Testing image fetch for: #{restaurant.name}"
    puts "Place ID: #{restaurant.place_id}"
    puts "Current image URL: #{restaurant.image_url || 'nil'}"
    
    if restaurant.place_id.present? && restaurant.place_id != "id place-id-input" && !restaurant.place_id.start_with?("id ")
      begin
        FetchRestaurantImageJob.perform_now(restaurant.id)
        restaurant.reload
        puts "New image URL: #{restaurant.image_url || 'FAILED'}"
      rescue => e
        puts "Error: #{e.message}"
        puts e.backtrace.first(5)
      end
    else
      puts "Invalid place_id! Need to update with a real Google Places place_id"
      puts "\nTo fix:"
      puts "1. Go to the restaurant edit page"
      puts "2. Use Google Places autocomplete to select the restaurant"
      puts "3. Save - the image will be fetched automatically"
    end
  end
  
  desc "Show restaurant details for debugging"
  task :debug, [:restaurant_id] => :environment do |t, args|
    restaurant = Restaurant.find(args[:restaurant_id])
    puts "Restaurant: #{restaurant.name}"
    puts "Place ID: #{restaurant.place_id || 'nil'}"
    puts "Place ID valid: #{restaurant.place_id.present? && restaurant.place_id != 'id place-id-input' && !restaurant.place_id.start_with?('id ') ? 'YES' : 'NO'}"
    puts "Image URL: #{restaurant.image_url || 'nil'}"
    puts "API Key present: #{ENV['GOOGLE_PLACES_API_KEY'].present? ? 'YES' : 'NO'}"
  end
  
  desc "Update a restaurant's place_id manually (for testing)"
  task :update_place_id, [:restaurant_id, :place_id] => :environment do |t, args|
    restaurant = Restaurant.find(args[:restaurant_id])
    old_place_id = restaurant.place_id
    restaurant.update(place_id: args[:place_id])
    puts "Updated restaurant #{restaurant.name}:"
    puts "  Old place_id: #{old_place_id}"
    puts "  New place_id: #{restaurant.place_id}"
    puts "\nFetching image..."
    FetchRestaurantImageJob.perform_now(restaurant.id)
    restaurant.reload
    puts "Image URL: #{restaurant.image_url || 'FAILED'}"
  end
end
