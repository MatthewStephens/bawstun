Bawstun::Application.routes.draw do
  mount RailsAdmin::Engine => '/admin', :as => 'rails_admin'

  root :to => "catalog#index"

  Blacklight.add_routes(self)
  HydraHead.add_routes(self)
  Hydra::BatchEdit.add_routes(self)


  devise_for :users, :controllers => { :omniauth_callbacks => "users/omniauth_callbacks" }
  
  mount Sufia::Engine => '/'

end
