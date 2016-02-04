
# Menu
get 'planning', :to => 'planning#index'
post 'planning', :to => 'planning#index'

# Planning by projects
get 'planning/projects', :to => 'planning#planning_by_projects'
post 'planning/projects', :to => 'planning#planning_by_projects'

# Planning by people
get 'planning/people', :to => 'planning#planning_by_people'
post 'planning/people', :to => 'planning#planning_by_people'

# Responsibilities
get 'responsibilities', :to => 'responsibilities#index'
post 'responsibilities', :to => 'responsibilities#index'

#match 'planning/people/:dtini/:dtend' => 'planning#planning_by_people', :via => :get, as: :planning_by_people_dates