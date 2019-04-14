Rails.application.routes.draw do
  get 'home/index'
  match 'home/grant', via: %i[get post put]
  match 'home/quick_books_oauth_callback', via: %i[get post put]
end
