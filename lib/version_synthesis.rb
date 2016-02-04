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

class VersionSynthesis
  def initialize(project, version, issues)
    @version = version
    @project = project
    @issues = Array.new

    @statuses = Hash.new 

    @total_nb = 0

    @closed_nb = 0
    @opened_nb = 0

    @closed_pct = 0
    @opened_pct = 0

    @max_depth=0
    self.add_issues(issues)
  end

  def add_issues(issues)


    @total_nb += issues.length

    issues.each{ |issue|

      if issue.closed? or issue.done_ratio == 100
        @closed_nb += 1
      end

      if @statuses[issue.status.to_s].nil?
        @statuses[issue.status.to_s] = [issue]
      else
        @statuses[issue.status.to_s].push(issue)
      end

      # TODO: Create a hierarchy structure to show 
      depth=issues.select{|iss| (iss.lft<issue.lft) && (iss.rgt>issue.rgt) && (iss.id!=issue.id) && (iss.root_id==issue.root_id) }.length
      @issues.push(IssueWrapper.new(issue,depth))
      if @max_depth<depth
        @max_depth = depth
      end
    }

    if @total_nb > 0
      @opened_nb = @total_nb - @closed_nb
      @closed_pct = @closed_nb*100/@total_nb
      @opened_pct = @opened_nb*100/@total_nb
    end
  end
    
  attr_reader :version, :project, :max_depth, :statuses, :issues, :closed_nb, :closed_pct, :opened_nb, :opened_pct, :total_nb
end