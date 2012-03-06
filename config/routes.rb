::Refinery::Application.routes.draw do
  scope(:path => 'refinery', :as => 'admin', :module => 'admin') do
    scope(:path => 'elements', :as => 'elements', :module => 'elements') do
      root :to => 'documents#index'

      resources :documents do
        collection do
          post :update_positions
        end
      end

      resources :descriptors do
        collection do
          get :widgets
        end
      end
    end
  end
end
