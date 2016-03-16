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

  module TaskStatusEnum
    ALL = "0"
    WITHOUT_ISSUES_OPENED = "1"
    WITH_ISSUES_OPENED = "2"
    WITH_ISSUES_OVERDUE = "3"
    WITH_ISSUES_UNPLANNED = "4"
  end
  
  def planning_by_people
    @users_grouped = Set.new
    @groups = Set.new
    @projects = Set.new
    @requesters = Set.new
    @requesters_sector = Set.new


    @param_username = params[:username] if params[:username]
    if !params[:issues_status].nil?
      @param_issues_status = params[:issues_status] 
    else 
      @param_issues_status = TaskStatusEnum::WITH_ISSUES_OPENED
    end
    @param_dtini = params[:dtini] if params[:dtini]
    @param_dtend = params[:dtend] if params[:dtend]
    @param_dtini_estimated = params[:dtini_estimated] if params[:dtini_estimated]
    @param_dtend_estimated = params[:dtend_estimated] if params[:dtend_estimated]
    @param_projects = params[:projects].collect { |id| id }.delete_if { |id| id == "" } if !params[:projects].nil?
    if !params[:filter_by_projects_not_in].nil?
      @param_projects_not_in = params[:filter_by_projects_not_in]
    else
      @param_projects_not_in = false
    end
    @param_requester = params[:requester]
    @param_requester_sector = params[:requester_sector]
    @param_groups = params[:groups].collect { |id| id }.delete_if { |id| id == "" } if !params[:groups].nil?
    @param_ocomon_number = params[:ocomon_number]
    @param_only_ocomon = !params[:filter_only_ocomon].nil? ? params[:filter_only_ocomon] : false



    logger = Logger.new("/u01/redmine/redmine/log/teste.log", shift_age = 7, shift_size = 1048576)

    #logger.info { "parametro issue status:  #{ @param_issues_status }" }
    

    @count_issues_opened = 0
    @count_issues_closed = 0

    users = User.active.order(:firstname)
    users.each_with_index { |user, index|

      usercontainsgroup = @param_groups.nil?
      user.groups.each { |group|
        if (!@param_groups.nil? && @param_groups.include?(group.id.to_s))
          usercontainsgroup = true
          break
        end
      }

      if !@param_username.nil? && !user.name.upcase.include?(@param_username.upcase)
        next
      end

      if usercontainsgroup

          planning = PlanningHelper::planning_issue_by_user_advanced(
            user, index, @param_dtini, @param_dtend, 
            @param_dtini_estimated, @param_dtend_estimated,
            @param_projects_not_in, @param_projects,
            @param_requester, @param_requester_sector, @param_ocomon_number, @param_only_ocomon)

          if ( 
            (@param_issues_status == TaskStatusEnum::ALL) ||
            (@param_issues_status == TaskStatusEnum::WITHOUT_ISSUES_OPENED && planning.issues.length == 0) ||
            (@param_issues_status == TaskStatusEnum::WITH_ISSUES_OPENED && planning.issues.length > 0) ||
            (@param_issues_status == TaskStatusEnum::WITH_ISSUES_OVERDUE && planning.total_overdue > 0) ||
            (@param_issues_status == TaskStatusEnum::WITH_ISSUES_UNPLANNED && planning.total_unplanned > 0)
            )

            @users_grouped.add(planning)
            @count_issues_opened += planning.issues.length
            @count_issues_closed += planning.issues_closed.length
          end

      end

    }


    @groups = Group.where.not( :id => [107,108] )
    @requesters = CustomField.find(5).possible_values
    @requesters_sector = CustomField.find(11).possible_values
    @projects = Project.where(:parent_id => nil)

  end



  def planning_by_projects_v2
    projects_filtred = Set.new
    projects = Project.includes(:issue_custom_fields).all

    logger = Logger.new("/u01/redmine/redmine/log/teste.log", shift_age = 7, shift_size = 1048576)
    #logger.info { "dtini: #{dtini}" }

    #http://www.redmine.org/projects/redmine/wiki/Rest_Projects
    #http://10.2.3.114/redmine/planning/projects
    #http://www.mitchcrowe.com/10-most-underused-activerecord-relation-methods/
    #http://guides.rubyonrails.org/active_record_querying.html#joining-tables

    projects.each do |project|
      project.custom_field_values.each{ |field_value|
        f_id = field_value.custom_field.id
        f_value = field_value.value

        #logger.info { "#{project.name}: #{f_id} (#{f_value}) -> #{f_value.class.name}" }
        if (f_id == 13 && f_value.to_s == "1")
          projects_filtred.add(PlanningHelper::planning_projects(project))
        end
      }
    end

    @projects = projects_filtred
  end




  #deprecated
  def planning_by_projects
    get_queryPlanning

    @user_synthesis = Hash.new

    ActiveRecord::Base.logger = Logger.new("/u01/redmine/redmine/log/sql.log", shift_age = 7, shift_size = 1048576)
    logger = Logger.new("/u01/redmine/redmine/log/teste.log", shift_age = 7, shift_size = 1048576)

    if @queryPlanning.has_filter?('tracker_id')
      #tracker_list = Tracker.find(:all, :is_in_roadmaps, :conditions => [@queryPlanning.statement_for('tracker_id').gsub('issues.tracker_id','trackers.id')], :order => 'position')
      Tracker.all.order(:position)
      #:conditions => [@queryPlanning.statement_for('tracker_id').gsub('issues.tracker_id','trackers.id')]
      tracker_list = Tracker.all.select(:tracker_id).order(:position)
    else 
      tracker_list = Tracker.all.select(:tracker_id).order(:position)
    end

    if @queryPlanning.has_filter?('group_id')
      projects_ids = CustomValue.select('customized_id').where(@queryPlanning.sql_for_field_for('group_id', 'custom_values', 'value')).collect {|v| v.customized_id}
      project_list = Project.find(projects_ids)
    end

    # condition hacked from the Query model to match versions
    version_condition = '(versions.status <> \'closed\')'
    version_condition += ' and ('+@queryPlanning.statement_for('project_id').gsub('issues','versions')+' or exists (select 1 from issues where issues.fixed_version_id = versions.id and '+@queryPlanning.statement_for('project_id')+'))' if @queryPlanning.has_filter?('project_id')


    #Version.find(:all, :conditions => [version_condition] ) \
    Version.all.where(version_condition) \
    .select{|version| !version.completed? } \
    .each{|version|

      issue_condition = ''
      issue_condition += @queryPlanning.statement_for('project_id')+' and ' unless @queryPlanning.statement_for('project_id').nil? 
      
      # Changed condition to get only issues on version.
      issue_condition += 'issues.tracker_id in (?) and fixed_version_id = ? '
      issue_condition += ' and issues.project_id in (?) ' unless project_list.nil?
      
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

      logger.info { "MA OE: #{@queryPlanning.statement_for('project_id')}" }

      #:order => 'project_id, tracker_id' )
      Issue.visible.all.where(issue_condition).includes(:status,:tracker).each {|issue|
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
  
  def get_queryPlanning

    logger = Logger.new("/u01/redmine/redmine/log/teste.log", shift_age = 7, shift_size = 1048576)
    

    @queryPlanning = Query.new(:name => "_", :filters => {})
    #projetos
    user_projects = Project.visible
    #tipos de tarefas (suporte, corretiva, evolutiva, adaptativa, etc.)
    user_trackers = Tracker.all

    filters = Hash.new
    filters['project_id'] = { :type => :list_optional, :values => user_projects.sort{|a,b| a.self_and_ancestors.join('/')<=>b.self_and_ancestors.join('/') }.collect{|s| [s.self_and_ancestors.join('/'), s.id.to_s] } } unless user_projects.empty?
    filters['tracker_id'] = { :type => :list, :values => Tracker.all.order(:position).collect{|s| [s.name, s.id.to_s] } } unless user_trackers.empty?
    filters['group_id']   = { :name => 'Grupo' ,:type => :list_optional, :values => ProjectCustomField.find_by_name('Grupo').possible_values}

    @queryPlanning.override_available_filters(filters)
    if params[:f]
      build_query_from_params
    end
    @queryPlanning.filters={ 'project_id' => {:operator => "*", :values => [""]} } if @queryPlanning.filters.length==0
  end
end
