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

require_dependency 'query'
require 'cgi'
require 'date'

module PlanningHelper

  def self.planning_issue_by_user(user)
    self.planning_issue_by_user_advanced(user, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil)
  end

  def self.planning_issue_by_user_advanced(user, index = 0, dtini, dtend, dtini_estimated, dtend_estimated, filter_by_projects_not_in, projects, requester, requester_sector, ocomon_number, only_ocomon)
    #datas acima dos limites para evitar ifs de datas nulas

    logger = Logger.new("/u01/redmine/redmine/log/teste.log", shift_age = 7, shift_size = 1048576)
    #logger.info { "dtini: #{dtini}" }

    dtini = self.format_date(dtini)
    dtend = self.format_date(dtend)
    dtini_estimated = self.format_date(dtini_estimated)
    dtend_estimated = self.format_date(dtend_estimated)


    requester = "" if requester.nil?
    requester_sector = "" if requester_sector.nil?

    query = "assigned_to_id = :user"
    query += " AND (:dtini is NULL OR start_date >= :dtini)"
    query += " AND (:dtend is NULL OR start_date <= :dtend)"
    query += " AND (:dtini_estimated is NULL OR due_date >= :dtini_estimated)"
    query += " AND (:dtend_estimated is NULL OR due_date <= :dtend_estimated)"

    if !projects.nil? && !projects.empty?
      if filter_by_projects_not_in == "true"
        query += " AND project_id NOT IN (:projects)"
      else
        query += " AND project_id IN (:projects)"
      end
    end

    issues = Issue.open.includes(:status).where(query, { 
      user: user, projects: projects, 
      dtini: dtini, dtend: dtend, 
      dtini_estimated: dtini_estimated, dtend_estimated: dtend_estimated
    })


    # VERIFY CUSTOM FIELDS
    verify_eq = 0

    issues_filtred = Set.new
    
    if (!requester.nil? && !requester.empty?)
      verify_eq = verify_eq.succ
      verify_req = true
    end
    if (!requester_sector.nil? && !requester_sector.empty?)
      verify_eq = verify_eq.succ
      verify_req_sec = true
    end
    if (!ocomon_number.nil? && !ocomon_number.strip.empty?)
      verify_eq = verify_eq.succ
      verify_req_ocomon_num = true
    end
    if (!only_ocomon.nil? && only_ocomon)
      verify_eq = verify_eq.succ
      verify_req_only_comon = true
    end
    


    issues = issues.each{ |issue|
      count_eq = 0
      
      #logger.info { "custom_field_values: #{issue.custom_field_values}" }

      issue.custom_field_values.each{ |field_value|
        f_id = field_value.custom_field.id
        f_value = field_value.value

        #solicitante
        if (verify_req == true && f_id == 5 && !f_value.nil? && f_value.upcase == CGI.unescapeHTML(requester.upcase))
          count_eq += 1
        end

        #setor solicitante
        if (verify_req_sec == true && f_id == 11 && !f_value.nil? && f_value.upcase == CGI.unescapeHTML(requester_sector.upcase))
          count_eq += 1
        end

        #ocomon number
        if (verify_req_ocomon_num == true && f_id == 1 && f_value == ocomon_number.strip)
          count_eq += 1
        end

        #contains ocomon number
        if (verify_req_only_comon == true && f_id == 1 && !f_value.nil? && !f_value.empty?)
          count_eq += 1
        end
      }

      if count_eq == verify_eq
        issues_filtred.add(issue)
      end
    }

    #busca por tarefas fechadas no mês atual

    #joins(:status).where("#{IssueStatus.table_name}.is_closed = ?", is_closed)
    #.open(false)

    issues_closed = Set.new

    today = Date.today
    initDate = Date.new(today.year, today.month, 1)
    lastDate = Date.new(today.year, today.month, -1)

    #TODO: area administrativa para controlar situações, nesse caso = fechada
    query_opened = "assigned_to_id = :user AND status_id = 5"
    query_opened += " AND (:dtini_estimated is NULL OR closed_on >= :dtini_estimated)"
    query_opened += " AND (:dtend_estimated is NULL OR closed_on <= :dtend_estimated)"

    issues_closed = Issue.open(false).includes(:status).where(query_opened, { 
      user: user, dtini_estimated: initDate, dtend_estimated: lastDate
    })


    #busca por tarefas em progresso (status = 2)
    issues_in_progress = Set.new

    issues_filtred.each{ |issue|
      if issue.status_id == 2
        issues_in_progress.add(issue)
      end
    }

    
    IssueByUser.new(user, issues_filtred, issues_closed, issues_in_progress, index)
  end

  def self.format_date(date)
    return Date.strptime(date, "%d/%m/%Y") if !date.nil? && !date.empty?
  end


  def self.planning_projects(project)
    IssueByProject.new(project.issues)
  end




  
  module VersionPatch
    def self.included(base)
      base.send(:include, InstanceMethods)
    end
    module InstanceMethods
      def splitted_version_name
        return self.name.split(/[^a-zA-Z0-9]/).compact.map{ |elem|
          (elem.to_i.to_s!=elem)?(elem.to_s):('%010d' % elem.to_i)
         }
      end
    end
  end
  
  module IssuePatch
    def self.included(base)
      base.send(:include, InstanceMethods)
    end
    module InstanceMethods
      def planning_status
        if self.status.name == 'Em Pausa'
          return :paused
        elsif self.due_date.nil?
           return :unplanned
        elsif self.due_date >= Time.new.to_date
           return :in_time
        else
           return :overdue
        end
      end
    end
  end
  
  module QueryPatch
    def self.included(base)
      base.send(:include, InstanceMethods)
    end
    
    module InstanceMethods
      def override_available_filters(new_filters=nil)
        @available_filters = new_filters if (!new_filters.nil? && new_filters.is_a?(Hash))
      end

      def sql_for_field_for(field, db_table, db_field, is_custom_filter=false)
        sql_for_field(field, operator_for(field), values_for(field), db_table, db_field, is_custom_filter)
      end
      
      def statement_for(field_name)
        # Copy/pasted from Query.statement
        # filters clauses
        filters_clauses = []
        filters.each_key do |field|
          next if field == "subproject_id" || field != field_name
          v = values_for(field).clone
          next unless v and !v.empty?
          operator = operator_for(field)
    
          # "me" value substitution
          if %w(assigned_to_id author_id watcher_id).include?(field)
            if v.delete("me")
              if User.current.logged?
                v.push(User.current.id.to_s)
                v += User.current.group_ids.map(&:to_s) if field == 'assigned_to_id'
              else
                v.push("0")
              end
            end
          end
    
          if field =~ /^cf_(\d+)$/
            # custom field
            filters_clauses << sql_for_custom_field(field, operator, v, $1)
          elsif respond_to?("sql_for_#{field}_field")
            # specific statement
            filters_clauses << send("sql_for_#{field}_field", field, operator, v)
          else
            # regular field
            filters_clauses << '(' + sql_for_field(field, operator, v, Issue.table_name, field) + ')'
          end
        end if filters and valid?
    
        filters_clauses << project_statement
        filters_clauses.reject!(&:blank?)
    
        filters_clauses.any? ? filters_clauses.join(' AND ') : nil
      end
    end
  end
  
  Query.send(:include, QueryPatch)
  Issue.send(:include, IssuePatch)
  Version.send(:include, VersionPatch)
end
