Refinery::Core::Engine.routes.draw do

  namespace :admin, :path => 'refinery' do
    namespace :elements do
      root :to => 'documents#index'

      resources :documents do
        collection do
          post :update_positions
        end
      end
    end
  end

end
