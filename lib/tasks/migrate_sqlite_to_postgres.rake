namespace :db do
  desc "Migrate data from SQLite to PostgreSQL"
  task migrate_from_sqlite: :environment do
    # Ce script doit être exécuté sur Fly.io avec le volume SQLite monté
    
    sqlite_db_path = '/data/production.sqlite3'
    
    unless File.exist?(sqlite_db_path)
      puts "❌ SQLite database not found at #{sqlite_db_path}"
      exit 1
    end
    
    puts "✅ SQLite database found!"
    puts "🔄 Starting migration..."
    
    # Configuration SQLite temporaire
    sqlite_config = {
      adapter: 'sqlite3',
      database: sqlite_db_path
    }
    
    # Connexion à SQLite
    sqlite_conn = ActiveRecord::Base.establish_connection(sqlite_config).connection
    
    # Reconnexion à PostgreSQL pour l'écriture
    postgres_conn = ActiveRecord::Base.establish_connection(:production).connection
    
    # Migration des tables
    tables_to_migrate = ['users', 'restaurants', 'reviews', 'friendships', 'notifications', 'noticed_events', 'noticed_notifications']
    
    tables_to_migrate.each do |table|
      next unless sqlite_conn.table_exists?(table)
      
      puts "\n📋 Migrating table: #{table}"
      
      # Lire depuis SQLite
      rows = sqlite_conn.execute("SELECT * FROM #{table}")
      columns = sqlite_conn.columns(table).map(&:name)
      
      puts "   Found #{rows.count} rows"
      
      next if rows.empty?
      
      # Insérer dans PostgreSQL
      rows.each_with_index do |row, index|
        values = {}
        columns.each_with_index do |col, col_index|
          values[col] = row[col_index]
        end
        
        # Utiliser l'ID original si disponible
        if values['id']
          postgres_conn.execute("SELECT setval('#{table}_id_seq', #{values['id']}, true)") rescue nil
        end
        
        # Insérer
        column_names = values.keys.join(', ')
        placeholders = values.keys.map.with_index { |_, i| "$#{i + 1}" }.join(', ')
        
        begin
          postgres_conn.execute(
            "INSERT INTO #{table} (#{column_names}) VALUES (#{placeholders})",
            *values.values
          )
        rescue => e
          puts "   ⚠️  Error inserting row #{index + 1}: #{e.message}"
        end
        
        print "\r   Progress: #{index + 1}/#{rows.count}" if (index + 1) % 10 == 0
      end
      
      puts "\n   ✅ Completed!"
    end
    
    puts "\n🎉 Migration completed!"
    
    # Reconnecter à PostgreSQL
    ActiveRecord::Base.establish_connection(:production)
  end
end

