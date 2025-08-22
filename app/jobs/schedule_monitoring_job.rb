class ScheduleMonitoringJob < ApplicationJob
  queue_as :default

  def perform
    SiteMonitor.includes(:company).find_each do |site_monitor|
      next unless site_monitor.should_check?
      
      MonitorCheckJob.perform_later(site_monitor.id)
    end
    
    Rails.logger.info "Scheduled monitoring checks for all eligible monitors"
  end
end