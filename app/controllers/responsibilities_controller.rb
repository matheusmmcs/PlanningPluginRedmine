
class ResponsibilitiesController < ApplicationController
  unloadable
  before_filter :authorize_planning
  
  helper_method :responsibilities_render_project_hierarchy
  
  def index
    @projects = Project.active.order('lft asc')
  end
  
  private
  
  def responsibilities_render_project_hierarchy(projects)
    s = ''
    if projects.any?
      ancestors = []
      original_project = @project
      projects.each do |project|
        # set the project environment to please macros.
        @project = project
        if (ancestors.empty? || project.is_descendant_of?(ancestors.last))
          s << "<ul class='projects #{ ancestors.empty? ? 'root' : nil}'>\n"
        else
          ancestors.pop
          s << "</li>"
          while (ancestors.any? && !project.is_descendant_of?(ancestors.last))
            ancestors.pop
            s << "</ul></li>\n"
          end
        end
        classes = (ancestors.empty? ? 'root' : 'child')
        s << "<li class='#{classes}'><div class='#{classes}'>" +
               view_context.link_to_project(project, {}, :class => "project #{User.current.member_of?(project) ? 'my-project' : nil}")
        s << "<table id='issue-table' >"
        s << "<thead>"
        s << "<tr>"
        project.users_by_role.keys.sort{ |x,y| x.position <=> y.position }.each { |role| 
          s <<    "<th style='width: #{100 / project.users_by_role.keys.length }%' >#{role.name}</th>"
        } 
        s << "</tr>"
        s << "</thead>"
        
        s << "<tbody>"
        s << "<tr>"
        project.users_by_role.keys.sort{ |x,y| x.position <=> y.position }.each { |role|
        s << "<td>"
        s << project.users_by_role[role].map { |user| view_context.link_to_user(user) }.join(", ")
        #users_truncate = view_context.truncate(users, :length => 17, :separator => ' ')
        #s << "<span>#{users_truncate} <a href='javascript: void();' onclick='$(this).previous().textContent=\"#{users}\"'>...</a></span>"
        s << "</td>"
        }
        s << "</tr>"
        s << "</tbody>"
        s << "</table>"
        s << "</div>\n"
        ancestors << project
      end
      s << ("</li></ul>\n" * ancestors.size)
      @project = original_project
    end
    s.html_safe
  end
  
  def authorize_planning
    if !(User.current.allowed_to?(:view_responsibilities, nil, :global => true) || User.current.admin?)
      render_403
      return false
    end
    return true
  end
  
end
