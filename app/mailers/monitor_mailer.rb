class MonitorMailer < ApplicationMailer
  default from: 'alerts@monitor.rrbstudio.com'

  def downtime_alert(user, site_monitor)
    @user = user
    @site_monitor = site_monitor
    @company = site_monitor.company
    @last_check = site_monitor.last_check

    mail(
      to: user.email,
      subject: "🔴 #{site_monitor.name} is DOWN"
    )
  end

  def uptime_alert(user, site_monitor)
    @user = user
    @site_monitor = site_monitor
    @company = site_monitor.company
    @last_check = site_monitor.last_check

    mail(
      to: user.email,
      subject: "✅ #{site_monitor.name} is back UP"
    )
  end

  def weekly_report(user, site_monitors)
    @user = user
    @site_monitors = site_monitors
    @company = user.company

    mail(
      to: user.email,
      subject: "Weekly Uptime Report - #{@company.name}"
    )
  end
end