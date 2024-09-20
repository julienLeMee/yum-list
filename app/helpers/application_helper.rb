module ApplicationHelper
  def theme_color_for_page
    case [controller_name, action_name]
    when ['restaurants', 'new'],
        ['restaurants', 'index'],
        ['restaurants', 'show'],
        ['restaurants', 'tested_restaurants'],
        ['restaurants', 'untested_restaurants'],
        ['restaurants', 'categories'],
        ['friendships', 'new'],
        ['friendships', 'pending_requests'],
        ['friends', 'index'],
        ['users', 'show'],
        ['users', 'friend_restaurants'],
        ['users', 'friends']
      '#F5F5F5' # Couleur spécifique pour ces contrôleurs et actions
    else
      '#B1454A' # Couleur par défaut
    end
  end
end
