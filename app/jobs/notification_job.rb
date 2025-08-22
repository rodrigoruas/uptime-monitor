class NotificationJob < ApplicationJob
  queue_as :default

  def perform(site_monitor_id, event_type)
    site_monitor = SiteMonitor.find(site_monitor_id)
    
    case event_type
    when 'down'
      send_downtime_notification(site_monitor)
    when 'up'
      send_uptime_notification(site_monitor)
    end
  end

  private

  def send_downtime_notification(site_monitor)
    site_monitor.company.users.each do |user|
      MonitorMailer.downtime_alert(user, site_monitor).deliver_now
    end
    
    Rails.logger.info "Sent downtime notification for #{site_monitor.name}"
  end

  def send_uptime_notification(site_monitor)
    site_monitor.company.users.each do |user|
      MonitorMailer.uptime_alert(user, site_monitor).deliver_now
    end
    
    Rails.logger.info "Sent uptime notification for #{site_monitor.name}"
  end
end