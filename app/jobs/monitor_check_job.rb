class MonitorCheckJob < ApplicationJob
  queue_as :default

  def perform(site_monitor_id)
    site_monitor = SiteMonitor.find(site_monitor_id)
    
    start_time = Time.current
    
    begin
      response = Faraday.get(site_monitor.url) do |req|
        req.options.timeout = 30
        req.options.open_timeout = 10
        req.headers['User-Agent'] = 'UptimeMonitor/1.0'
      end
      
      response_time = ((Time.current - start_time) * 1000).round(2)
      status_code = response.status
      
      # Create monitor check record
      MonitorCheck.create!(
        site_monitor: site_monitor,
        status_code: status_code,
        response_time: response_time,
        checked_at: Time.current
      )
      
      # Update monitor status
      new_status = status_code.between?(200, 299) ? 'up' : 'down'
      site_monitor.update!(
        status: new_status,
        last_checked_at: Time.current
      )
      
      # Send notification if status changed from up to down
      if site_monitor.status_previously_was == 'up' && new_status == 'down'
        NotificationJob.perform_later(site_monitor.id, 'down')
      elsif site_monitor.status_previously_was == 'down' && new_status == 'up'
        NotificationJob.perform_later(site_monitor.id, 'up')
      end
      
      # Broadcast real-time update
      ActionCable.server.broadcast(
        "monitors_#{site_monitor.company_id}",
        {
          monitor_id: site_monitor.id,
          status: new_status,
          response_time: response_time,
          checked_at: Time.current.iso8601,
          uptime_percentage: site_monitor.uptime_percentage
        }
      )
      
      Rails.logger.info "Monitor check completed: #{site_monitor.name} - Status: #{status_code} - Response time: #{response_time}ms"
      
    rescue Faraday::TimeoutError, Faraday::ConnectionFailed => e
      handle_monitor_error(site_monitor, e, 'timeout')
    rescue => e
      handle_monitor_error(site_monitor, e, 'error')
    end
  end

  private

  def handle_monitor_error(site_monitor, error, error_type)
    MonitorCheck.create!(
      site_monitor: site_monitor,
      status_code: nil,
      response_time: nil,
      checked_at: Time.current,
      error_message: error.message
    )
    
    site_monitor.update!(
      status: 'down',
      last_checked_at: Time.current
    )
    
    # Send notification if status changed from up to down
    if site_monitor.status_previously_was == 'up'
      NotificationJob.perform_later(site_monitor.id, 'down')
    end
    
    # Broadcast real-time update
    ActionCable.server.broadcast(
      "monitors_#{site_monitor.company_id}",
      {
        monitor_id: site_monitor.id,
        status: 'down',
        error: error.message,
        checked_at: Time.current.iso8601,
        uptime_percentage: site_monitor.uptime_percentage
      }
    )
    
    Rails.logger.error "Monitor check failed: #{site_monitor.name} - Error: #{error.message}"
  end
end