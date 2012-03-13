module Refinery
  class ElementsGenerator < Rails::Generators::Base

    def append_load_seed_data
      create_file "db/seeds.rb" unless File.exists?(File.join(destination_root, 'db', 'seeds.rb'))
      append_file 'db/seeds.rb', :verbose => true do
        <<-EOH

# Added by Refinery CMS Elements extension
Refinery::Elements::Engine.load_seed
        EOH
      end
    end

  end
end
