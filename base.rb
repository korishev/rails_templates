# setup rvm for ruby and gemset
file ".rvmrc", <<-END
rvm use ruby-1.8.7@rails3_base
END


# move database config out of the way
run "cp config/database.yml config/database.yml.example"

# setup environment bits for devise
environment "config.action_mailer.default_url_options = { :host => 'localhost:3000' }", :env => ["development", "production", "test"]

# get rid of junk files
run "rm README"
run "rm public/index.html"
run "rm public/favicon.ico"
run "rm public/robots.txt"
run "rm public/images/rails.png"
run "rm .gitignore"

# Set up .gitignore files
run "touch tmp/.gitignore log/.gitignore vendor/.gitignore"
run %{find . -type d -empty | grep -v "vendor" | grep -v ".git" | grep -v "tmp" | xargs -I xxx touch xxx/.gitignore}

file '.gitignore', <<-END
.idea
.project
.bundle
.DS_Store
log/*.log
tmp/**/*
config/database.yml
db/*.sqlite3
vendor/rails
END

file 'config/authorization_rules.rb', <<-END
authorization do
  role :guest do
    has_permission_on [:user_session, :user], :to => :create
  end

  role :user do
    includes :guest
  end

  role :admin do
    includes :user
      has_permission_on :authorization_rules, :to => :manage
      has_permission_on :authorization_usages, :to => :read
    end
  end

  privileges do
    # default privilege hierarchies to facilitate RESTful Rails apps
    privilege :manage, :includes => [:create, :read, :update, :delete]
    privilege :read, :includes => [:index, :show]
    privilege :create, :includes => :new
    privilege :update, :includes => :edit
    privilege :delete, :includes => :destroy
  end
END

run "mkdir public/stylesheets/sass"

gem 'haml'
gem 'hpricot'
gem 'ruby_parser'
gem 'devise'
gem 'declarative_authorization'
gem 'factory_girl'
gem 'pg'
gem 'sqlite3-ruby', :require => 'sqlite3'
gem 'heroku'

gem 'rspec', '>= 2.0.0', :group => [:development, :test]
gem 'rspec-rails', '>= 2.0.0', :group => [:development, :test]
gem 'cucumber-rails', '>= 0.3.2', :group => [:development, :test]
gem 'webrat', :group => [:development, :test]

run 'bundle install'

generate "rspec:install"
generate "cucumber:install"
generate "devise:install"
generate "model Role"
generate "controller Welcome index"
generate "devise User"
generate "devise:views user"

inside "spec" do
  run "mkdir support" 
end

inside "spec/support" do
  file "devise.rb", <<-END
RSpec.configure do |config|
  config.include Devise::TestHelpers, :type => :controller
end
END
end

#setup user -> roles associations
file_data = <<-END

  has_many :roles

  def role_symbols
    (roles || []).map {|role| role.title.to_sym}
  end
END
inject_into_file "app/models/user.rb", file_data, :after => /:remember_me$/i

file_data = <<-END

  belongs_to :user
		END

inject_into_file "app/models/role.rb", file_data, :after => /ActiveRecord::Base/i

route "root :to => 'welcome#index'"

#convert _everything_ to haml as the last step
run "for i in `find ./ -iname '*erb'`; do html2haml -e  $i `echo $i | sed 's/erb/haml/'`; rm -rf $i ; done"

# Set up git repository
git :init
git :add => '.'
git :commit => "-m 'Initial Commit'"

