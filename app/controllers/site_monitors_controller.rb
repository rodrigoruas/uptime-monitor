class SiteMonitorsController < ApplicationController
  before_action :set_site_monitor, only: [:show, :edit, :update, :destroy]

  def index
    @site_monitors = @current_company.site_monitors.includes(:monitor_checks)
  end

  def show
    @recent_checks = @site_monitor.monitor_checks.recent.limit(50)
    @uptime_data = calculate_uptime_data
  end

  def new
    @site_monitor = @current_company.site_monitors.build
    check_monitor_limit
  end

  def create
    @site_monitor = @current_company.site_monitors.build(site_monitor_params)
    
    if check_monitor_limit && @site_monitor.save
      # Perform initial check
      MonitorCheckJob.perform_later(@site_monitor.id)
      redirect_to @site_monitor, notice: 'Monitor was successfully created.'
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @site_monitor.update(site_monitor_params)
      redirect_to @site_monitor, notice: 'Monitor was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    @site_monitor.destroy
    redirect_to site_monitors_url, notice: 'Monitor was successfully deleted.'
  end

  private

  def set_site_monitor
    @site_monitor = @current_company.site_monitors.find(params[:id])
  end

  def site_monitor_params
    params.require(:site_monitor).permit(:name, :url)
  end

  def check_monitor_limit
    if @current_company.site_monitors.count >= @current_company.monitor_limit
      @site_monitor.errors.add(:base, "You've reached your monitor limit. Please upgrade your plan.")
      return false
    end
    true
  end

  def calculate_uptime_data
    # Calculate daily uptime for the last 30 days
    30.days.ago.to_date.upto(Date.current).map do |date|
      checks = @site_monitor.monitor_checks.where(checked_at: date.beginning_of_day..date.end_of_day)
      successful_checks = checks.successful.count
      total_checks = checks.count
      
      uptime_percentage = total_checks > 0 ? (successful_checks.to_f / total_checks * 100).round(2) : 0
      
      {
        date: date.strftime('%m/%d'),
        uptime: uptime_percentage,
        status: uptime_percentage >= 99 ? 'good' : uptime_percentage >= 95 ? 'warning' : 'down'
      }
    end
  end
end
