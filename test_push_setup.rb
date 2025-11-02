#!/usr/bin/env ruby
# Script de vérification de l'installation des notifications push

puts "🔍 Vérification de l'installation des notifications push...\n\n"

# Vérifier les variables d'environnement
puts "1️⃣ Variables d'environnement VAPID :"
vapid_public = ENV['VAPID_PUBLIC_KEY']
vapid_private = ENV['VAPID_PRIVATE_KEY']
vapid_email = ENV['VAPID_EMAIL']

if vapid_public && vapid_private && vapid_email
  puts "   ✅ VAPID_PUBLIC_KEY : #{vapid_public[0..20]}..."
  puts "   ✅ VAPID_PRIVATE_KEY : #{vapid_private[0..20]}..."
  puts "   ✅ VAPID_EMAIL : #{vapid_email}"
else
  puts "   ❌ Variables VAPID manquantes !"
  puts "      Manquant : #{[
    vapid_public ? nil : 'VAPID_PUBLIC_KEY',
    vapid_private ? nil : 'VAPID_PRIVATE_KEY',
    vapid_email ? nil : 'VAPID_EMAIL'
  ].compact.join(', ')}"
  exit 1
end

puts "\n2️⃣ Modèles :"
require_relative 'config/environment'

begin
  PushSubscription
  puts "   ✅ Modèle PushSubscription existe"
rescue NameError
  puts "   ❌ Modèle PushSubscription introuvable"
  exit 1
end

puts "\n3️⃣ Base de données :"
begin
  PushSubscription.count
  puts "   ✅ Table push_subscriptions existe (#{PushSubscription.count} abonnements)"
rescue => e
  puts "   ❌ Erreur table push_subscriptions : #{e.message}"
  exit 1
end

puts "\n4️⃣ Associations :"
begin
  user = User.first || User.create!(email: "test@test.com", password: "password123")
  user.push_subscriptions
  puts "   ✅ Association User.push_subscriptions fonctionne"
rescue => e
  puts "   ❌ Erreur association : #{e.message}"
  exit 1
end

puts "\n5️⃣ Contrôleurs :"
begin
  PushSubscriptionsController
  puts "   ✅ Contrôleur PushSubscriptionsController existe"
rescue NameError
  puts "   ❌ Contrôleur PushSubscriptionsController introuvable"
  exit 1
end

puts "\n6️⃣ Routes :"
routes_ok = Rails.application.routes.routes.any? { |r| r.path.spec.to_s.include?('push_subscriptions') }
if routes_ok
  puts "   ✅ Routes push_subscriptions configurées"
else
  puts "   ❌ Routes push_subscriptions manquantes"
  exit 1
end

puts "\n7️⃣ Notifiers :"
web_push_channel_file = Rails.root.join('app', 'channels', 'noticed', 'web_push_channel.rb')
if File.exist?(web_push_channel_file)
  puts "   ✅ Fichier web_push_channel.rb existe"
  content = File.read(web_push_channel_file)
  if content.include?('module Noticed') && content.include?('class WebPushChannel')
    puts "   ✅ Structure Noticed::WebPushChannel correcte"
  else
    puts "   ❌ Structure du fichier incorrecte"
    exit 1
  end
else
  puts "   ❌ Fichier web_push_channel.rb introuvable"
  exit 1
end

puts "\n8️⃣ Fichiers publics :"
service_worker_exists = File.exist?(Rails.root.join('public', 'service-worker.js'))
manifest_exists = File.exist?(Rails.root.join('public', 'manifest.json'))

if service_worker_exists
  puts "   ✅ service-worker.js existe"
else
  puts "   ❌ service-worker.js manquant"
  exit 1
end

if manifest_exists
  puts "   ✅ manifest.json existe"
else
  puts "   ❌ manifest.json manquant"
  exit 1
end

puts "\n9️⃣ JavaScript :"
push_controller_exists = File.exist?(Rails.root.join('app', 'javascript', 'controllers', 'push_notifications_controller.js'))

if push_controller_exists
  puts "   ✅ Contrôleur Stimulus push_notifications existe"
else
  puts "   ❌ Contrôleur Stimulus push_notifications manquant"
  exit 1
end

puts "\n" + "="*60
puts "✅ Installation complète et fonctionnelle !"
puts "="*60
puts "\n📱 Prochaines étapes :"
puts "1. Démarrez le serveur : bin/dev"
puts "2. Ouvrez http://localhost:3000/notifications"
puts "3. Cliquez sur 'Activer les notifications'"
puts "4. Testez en créant un restaurant ou une demande d'ami"
puts "\n📖 Documentation : voir PUSH_NOTIFICATIONS.md"
puts "🚀 Déploiement : voir DEPLOYMENT_PUSH_NOTIFICATIONS.md\n"

