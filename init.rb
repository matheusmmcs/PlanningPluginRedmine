Redmine::Plugin.register :planning_plugin_redmine do
  name 'Planning plugin to Redmine'
  author 'Matheus Campanhã'
  description 'A plugin to track redmine issues and/or projects according to plan.'
  version '1.0.0'

  menu  :top_menu,
        :planning,
        { :controller => 'planning', :action => 'index' },
        :caption => :planning

  #menu :top_menu, :planning, { :controller => 'planning', :action => 'index' }, :caption => :planning , :if => Proc.new { User.current.allowed_to?(:view_planning, nil, :global => true) }
  #menu :top_menu, :responsibilities, { :controller => 'responsibilities', :action => 'index' }, :caption => :responsibilities , :if => Proc.new { User.current.allowed_to?(:view_responsibilities, nil, :global => true) }

  permission :view_planning, { :planning => :index }, :require => :loggedin
  permission :view_responsibilities, { :responsibilities => :index}, :require => :loggedin
  permission :view_planning_per_people, { :planning => :planning_by_people }, :require => :loggedin

  ProjectCustomField.create!(:name => 'Grupo', :is_required => false, :field_format => 'list', :possible_values => ['Planejamento Estrategico']) unless ProjectCustomField.find_by_name('Grupo')

end
