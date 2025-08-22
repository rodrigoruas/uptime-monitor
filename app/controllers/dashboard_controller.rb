class DashboardController < ApplicationController
  def index
    @site_monitors = @current_company.site_monitors.includes(:monitor_checks)
    @total_monitors = @site_monitors.count
    @monitors_up = @site_monitors.up.count
    @monitors_down = @site_monitors.down.count
    @average_uptime = calculate_average_uptime
    @recent_checks = MonitorCheck.joins(:site_monitor)
                                 .where(site_monitor: { company: @current_company })
                                 .recent
                                 .limit(10)
  end

  private

  def calculate_average_uptime
    return 0 if @site_monitors.empty?
    
    total_uptime = @site_monitors.sum { |monitor| monitor.uptime_percentage }
    (total_uptime / @site_monitors.count).round(2)
  end
end
