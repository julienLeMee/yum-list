#!/bin/bash
set -e

echo "🔄 Migration des données SQLite vers PostgreSQL"
echo "================================================"

# Vérifier que SQLite DB existe
if [ ! -f /data/production.sqlite3 ]; then
  echo "❌ Base SQLite introuvable à /data/production.sqlite3"
  exit 1
fi

echo "✅ Base SQLite trouvée"

# Installer postgresql-client si nécessaire
apt-get update -qq
apt-get install -y postgresql-client sqlite3

echo ""
echo "📊 Tables trouvées dans SQLite:"
sqlite3 /data/production.sqlite3 ".tables"

echo ""
echo "🔄 Export et import des données..."

# Liste des tables à migrer
TABLES="users restaurants reviews friendships notifications noticed_events noticed_notifications"

for TABLE in $TABLES; do
  # Vérifier si la table existe
  TABLE_EXISTS=$(sqlite3 /data/production.sqlite3 "SELECT name FROM sqlite_master WHERE type='table' AND name='$TABLE';" 2>/dev/null || echo "")
  
  if [ -z "$TABLE_EXISTS" ]; then
    echo "⚠️  Table $TABLE n'existe pas, skip"
    continue
  fi
  
  ROW_COUNT=$(sqlite3 /data/production.sqlite3 "SELECT COUNT(*) FROM $TABLE;" 2>/dev/null || echo "0")
  
  if [ "$ROW_COUNT" = "0" ]; then
    echo "⚠️  Table $TABLE est vide, skip"
    continue
  fi
  
  echo ""
  echo "📋 Migration de $TABLE ($ROW_COUNT lignes)..."
  
  # Export SQLite en CSV
  sqlite3 /data/production.sqlite3 <<EOF
.mode csv
.headers on
.output /tmp/${TABLE}.csv
SELECT * FROM ${TABLE};
.quit
EOF
  
  if [ -f "/tmp/${TABLE}.csv" ]; then
    # Import dans PostgreSQL
    # D'abord, vider la table
    psql $DATABASE_URL -c "TRUNCATE TABLE $TABLE CASCADE;" 2>/dev/null || echo "Table vide ou n'existe pas encore"
    
    # Import CSV
    psql $DATABASE_URL -c "\COPY $TABLE FROM '/tmp/${TABLE}.csv' WITH (FORMAT csv, HEADER true);" 2>&1 | grep -v "COPY" || true
    
    # Mettre à jour la séquence d'ID si applicable
    MAX_ID=$(psql $DATABASE_URL -t -c "SELECT MAX(id) FROM $TABLE;" 2>/dev/null | tr -d ' ')
    if [ ! -z "$MAX_ID" ] && [ "$MAX_ID" != "" ]; then
      psql $DATABASE_URL -c "SELECT setval('${TABLE}_id_seq', $MAX_ID, true);" 2>/dev/null || true
    fi
    
    echo "✅ $TABLE migré!"
    rm /tmp/${TABLE}.csv
  else
    echo "❌ Échec export $TABLE"
  fi
done

echo ""
echo "🎉 Migration terminée!"
echo ""
echo "📊 Résumé PostgreSQL:"
for TABLE in $TABLES; do
  COUNT=$(psql $DATABASE_URL -t -c "SELECT COUNT(*) FROM $TABLE;" 2>/dev/null | tr -d ' ' || echo "0")
  if [ "$COUNT" != "0" ]; then
    echo "  - $TABLE: $COUNT lignes"
  fi
done

