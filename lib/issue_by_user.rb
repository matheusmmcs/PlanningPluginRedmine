class IssueByUser
  
  attr_reader :user, :issues, :issues_closed, :issues_ocomon, :issues_priority, :issues_requester, :issues_requester_sector, :issues_status, :order, :total_paused, :total_unplanned, :total_overdue, :total_in_time, :total_paused_percent , :total_unplanned_percent, :total_overdue_percent, :total_in_time_percent
     
  def initialize(user, issues, issues_closed, order)
    @user = user
    @issues = issues
    @issues_closed = issues_closed
    @order = order

    @issues_ocomon = {}
    @issues_priority = {}
    @issues_requester = {}
    @issues_requester_sector = {}
    @issues_status = {}
    
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


        issue.custom_field_values.each { |field|
            if field.custom_field.name == "OCOMON"
              @issues_ocomon[issue.id.to_s] = field.value
            elsif field.custom_field.name.index("Prioridade") != -1
              @issues_priority[issue.id.to_s] = field.value
            end
            if field.custom_field.name.downcase == "solicitante"
              @issues_requester[issue.id.to_s] = field.value
            end
            if field.custom_field.name.downcase == "setor solicitante"
              @issues_requester_sector[issue.id.to_s] = field.value
            end
        }
      }
      
      @total_paused_percent = @total_paused * 100 / issues.length
      @total_unplanned_percent = @total_unplanned * 100 / issues.length
      @total_overdue_percent = @total_overdue * 100 / issues.length
      @total_in_time_percent = @total_in_time * 100 / issues.length
    end
    
  end
  
end