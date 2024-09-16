module ApplicationHelper
  def theme_color_for_page
    case [controller_name, action_name]
    when ['restaurants', 'new'],
        ['restaurants', 'tested_restaurants'],
        ['restaurants', 'untested-restaurants'],
        ['users', 'show']
      '#F5F5F5' # Couleur spécifique pour ces contrôleurs et actions
    else
      '#B1454A' # Couleur par défaut
    end
  end
end
