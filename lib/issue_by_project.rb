class IssueByProject
  
  attr_reader :issues, :total_paused, :total_unplanned, :total_overdue, :total_in_time, :total_paused_percent , :total_unplanned_percent, :total_overdue_percent, :total_in_time_percent
     
  def initialize(issues)

    @issues = issues
    
    @total_paused = 0
    @total_unplanned = 0
    @total_overdue = 0
    @total_in_time = 0
    
    @total_paused_percent = 0
    @total_unplanned_percent = 0
    @total_overdue_percent = 0
    @total_in_time_percent = 0
    
    if issues and not issues.empty?
      @issues.each { |issue|
        case issue.planning_status
          when :paused
            @total_paused += 1
            @issues_status[issue.id.to_s] = 'ft_gray'
          when :unplanned
            @total_unplanned += 1
            @issues_status[issue.id.to_s] = 'ft_yellow'
          when :in_time
            @total_in_time += 1
            @issues_status[issue.id.to_s] = 'ft_green'
          else
            @total_overdue += 1
            @issues_status[issue.id.to_s] = 'ft_red'
        end
      }
      
      @total_paused_percent = @total_paused * 100 / issues.length
      @total_unplanned_percent = @total_unplanned * 100 / issues.length
      @total_overdue_percent = @total_overdue * 100 / issues.length
      @total_in_time_percent = @total_in_time * 100 / issues.length
    end
    
  end
  
end