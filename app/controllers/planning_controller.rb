# My Roadmaps - Redmine plugin to expose global roadmaps 
# Copyright (C) 2012 Stéphane Rondinaud
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

require 'version_synthesis'
require 'set'
require 'issue_by_user'

class PlanningController < ApplicationController
  unloadable
  before_filter :authorize_planning
  
  include QueriesHelper
  
  def planning_by_people
    @users_grouped = Set.new
    @groups = Set.new
    if params[:dtini]
      @param_dtini = params[:dtini]
    end
    if params[:dtend]
      @param_dtend = params[:dtend]
    end
    users = User.active.order(:firstname)
    users.each_with_index { |user, index|
       @users_grouped.add(PlanningHelper::planning_issue_by_user(user, index, @param_dtini, @param_dtend))
       user.groups.each { |group|
          @groups.add(group);
       }
    }
  end

  def planning_by_projects
    get_query

    @user_synthesis = Hash.new

    if @query.has_filter?('tracker_id')
      tracker_list = Tracker.find(:all, :is_in_roadmaps, :conditions => [@query.statement_for('tracker_id').gsub('issues.tracker_id','trackers.id')], :order => 'position')
    else 
      tracker_list = Tracker.find(:all, :is_in_roadmaps, :order => 'position')
    end

    if @query.has_filter?('group_id')
      projects_ids = CustomValue.select('customized_id').where(@query.sql_for_field_for('group_id', 'custom_values', 'value')).collect {|v| v.customized_id}
      project_list = Project.find(projects_ids)
    end

    # condition hacked from the Query model to match versions
    version_condition = '(versions.status <> \'closed\')'
    version_condition += ' and ('+@query.statement_for('project_id').gsub('issues','versions')+' or exists (select 1 from issues where issues.fixed_version_id = versions.id and '+@query.statement_for('project_id')+'))' if @query.has_filter?('project_id')

    Version.find(:all, :conditions => [version_condition] ) \
    .select{|version| !version.completed? } \
    .each{|version|
      issue_condition = ''
      issue_condition += @query.statement_for('project_id')+' and ' unless @query.statement_for('project_id').nil? 
      # Changed condition to get only issues on version.
      issue_condition += 'tracker_id in (?) and fixed_version_id = ? '
      issue_condition += ' and project_id in (?) ' unless project_list.nil?
      
      #issue_condition += 'tracker_id in (?) and '+ \
      #  '( fixed_version_id = ? '+ \
      #  'or exists (select 1 '+ \
      #  'from issues as subissues '+ \
      #  'where issues.root_id = subissues.root_id '+ \
      #  'and subissues.fixed_version_id = ?) )'
      #issue_condition = [issue_condition, tracker_list, version.id, version.id]
      
      issue_condition = [issue_condition, tracker_list, version.id]

      issue_condition << project_list unless project_list.nil?

      grouped_issues = Hash.new
      Issue.visible.find(:all, :conditions => issue_condition, :include => [:status,:tracker], :order => 'project_id,tracker_id' ) \
      .each {|issue|
        if grouped_issues[issue.project].nil?
          grouped_issues[issue.project]=[issue]
        else
          grouped_issues[issue.project].push(issue)
        end
      }
      
      grouped_issues.each{|project, issues|
        if @user_synthesis[project].nil?
          @user_synthesis[project] = Hash.new
        end
        if @user_synthesis[project][version].nil?
          @user_synthesis[project][version] = VersionSynthesis.new(project, version, issues)
        else
          @user_synthesis[project][version].add_issues(issues)
        end
      }
    }
  end
  
  private
  
  def authorize_planning
    if !(User.current.allowed_to?(:view_planning, nil, :global => true) || User.current.admin?)
      render_403
      return false
    end
    return true
  end
  
  def get_query
    @query = Query.new(:name => "_", :filters => {})
    user_projects = Project.visible
    user_trackers = Tracker.find(:all, :is_in_roadmaps)

    filters = Hash.new
    filters['project_id'] = { :type => :list_optional, :order => 1, :values => user_projects.sort{|a,b| a.self_and_ancestors.join('/')<=>b.self_and_ancestors.join('/') }.collect{|s| [s.self_and_ancestors.join('/'), s.id.to_s] } } unless user_projects.empty?
    filters['tracker_id'] = { :type => :list, :order => 2, :values => Tracker.find(:all, :is_in_roodmaps, :order => 'position' ).collect{|s| [s.name, s.id.to_s] } } unless user_trackers.empty?
    filters['group_id']   = { :name => 'Grupo' ,:type => :list_optional, :order => 3, :values => ProjectCustomField.find_by_name('Grupo').possible_values}

    @query.override_available_filters(filters)
    if params[:f]
      build_query_from_params
    end
    @query.filters={ 'project_id' => {:operator => "*", :values => [""]} } if @query.filters.length==0
  end
end
