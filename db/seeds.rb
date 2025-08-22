# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

puts "🌱 Seeding database..."

# Create demo companies with different plan types
companies_data = [
  {
    name: "Acme Corp",
    plan_type: "professional",
    subscription_status: "active"
  },
  {
    name: "StartupXYZ",
    plan_type: "starter", 
    subscription_status: "active"
  },
  {
    name: "Enterprise Solutions Ltd",
    plan_type: "enterprise",
    subscription_status: "active"
  },
  {
    name: "FreeTier Demo",
    plan_type: "free",
    subscription_status: "inactive"
  }
]

companies = []
companies_data.each do |company_data|
  company = Company.find_or_create_by!(name: company_data[:name]) do |c|
    c.plan_type = company_data[:plan_type]
    c.subscription_status = company_data[:subscription_status]
    c.stripe_customer_id = "cus_demo_#{SecureRandom.hex(8)}" unless company_data[:plan_type] == "free"
  end
  companies << company
  puts "📊 Created company: #{company.name} (#{company.plan_type})"
end

# Create users for each company
users_data = [
  {
    company: companies[0], # Acme Corp
    first_name: "John",
    last_name: "Smith", 
    email: "john@acmecorp.com",
    role: "admin"
  },
  {
    company: companies[0], # Acme Corp
    first_name: "Sarah",
    last_name: "Johnson",
    email: "sarah@acmecorp.com", 
    role: "member"
  },
  {
    company: companies[1], # StartupXYZ
    first_name: "Mike",
    last_name: "Chen",
    email: "mike@startupxyz.com",
    role: "admin"
  },
  {
    company: companies[2], # Enterprise Solutions
    first_name: "Emily",
    last_name: "Rodriguez",
    email: "emily@enterprisesolutions.com",
    role: "admin"
  },
  {
    company: companies[2], # Enterprise Solutions
    first_name: "David",
    last_name: "Wilson",
    email: "david@enterprisesolutions.com",
    role: "member"
  },
  {
    company: companies[3], # FreeTier Demo
    first_name: "Alex",
    last_name: "Demo",
    email: "alex@freetier.com",
    role: "admin"
  }
]

users_data.each do |user_data|
  user = User.find_or_create_by!(email: user_data[:email]) do |u|
    u.first_name = user_data[:first_name]
    u.last_name = user_data[:last_name]
    u.company = user_data[:company]
    u.role = user_data[:role]
    u.password = "password123"
    u.password_confirmation = "password123"
  end
  puts "👤 Created user: #{user.full_name} (#{user.email}) - #{user.company.name}"
end

# Create sample monitors for each company
monitors_data = [
  # Acme Corp monitors (Professional plan - 25 monitors allowed)
  {
    company: companies[0],
    monitors: [
      { name: "Main Website", url: "https://acmecorp.com" },
      { name: "API Endpoint", url: "https://api.acmecorp.com/health" },
      { name: "Admin Dashboard", url: "https://admin.acmecorp.com" },
      { name: "Customer Portal", url: "https://portal.acmecorp.com" },
      { name: "Documentation", url: "https://docs.acmecorp.com" },
      { name: "Blog", url: "https://blog.acmecorp.com" }
    ]
  },
  # StartupXYZ monitors (Starter plan - 5 monitors allowed)
  {
    company: companies[1],
    monitors: [
      { name: "Landing Page", url: "https://startupxyz.com" },
      { name: "App Dashboard", url: "https://app.startupxyz.com" },
      { name: "API Health", url: "https://api.startupxyz.com/status" }
    ]
  },
  # Enterprise Solutions monitors (Enterprise plan - unlimited)
  {
    company: companies[2],
    monitors: [
      { name: "Corporate Website", url: "https://enterprisesolutions.com" },
      { name: "Client Portal", url: "https://clients.enterprisesolutions.com" },
      { name: "Internal Tools", url: "https://tools.enterprisesolutions.com" },
      { name: "API Gateway", url: "https://api.enterprisesolutions.com" },
      { name: "Documentation Portal", url: "https://docs.enterprisesolutions.com" },
      { name: "Support Center", url: "https://support.enterprisesolutions.com" },
      { name: "Employee Portal", url: "https://employees.enterprisesolutions.com" },
      { name: "File Storage", url: "https://files.enterprisesolutions.com" }
    ]
  },
  # FreeTier monitors (Free plan - 1 monitor allowed)
  {
    company: companies[3],
    monitors: [
      { name: "Personal Blog", url: "https://alexdemo.com" }
    ]
  }
]

monitors_data.each do |company_monitors|
  company = company_monitors[:company]
  company_monitors[:monitors].each do |monitor_data|
    monitor = SiteMonitor.find_or_create_by!(
      company: company,
      name: monitor_data[:name]
    ) do |m|
      m.url = monitor_data[:url]
      m.status = 'unknown'
      m.check_interval = company.check_interval_seconds
    end
    puts "🔍 Created monitor: #{monitor.name} (#{monitor.url}) - #{company.name}"
  end
end

# Create sample monitor checks (historical data)
puts "📈 Creating sample historical monitoring data..."

SiteMonitor.find_each do |monitor|
  # Create checks for the last 7 days
  7.days.ago.to_date.upto(Date.current) do |date|
    # Create 20-40 checks per day (simulating different check intervals)
    checks_count = rand(20..40)
    
    checks_count.times do |i|
      check_time = date.beginning_of_day + (i * (24.hours / checks_count)) + rand(-300..300).seconds
      
      # 95% uptime simulation - 95% of checks are successful
      is_successful = rand(100) < 95
      
      status_code = if is_successful
        [200, 201, 202].sample
      else
        [404, 500, 502, 503, 504, 0].sample # 0 for timeout/connection errors
      end
      
      response_time = if is_successful
        # Successful requests: 50-2000ms
        rand(50.0..2000.0).round(2)
      else
        # Failed requests might not have response time
        status_code == 0 ? nil : rand(5000.0..30000.0).round(2)
      end
      
      error_message = unless is_successful
        case status_code
        when 0
          ["Connection timeout", "Connection refused", "DNS resolution failed"].sample
        when 404
          "Not Found"
        when 500
          "Internal Server Error"
        when 502
          "Bad Gateway" 
        when 503
          "Service Unavailable"
        when 504
          "Gateway Timeout"
        end
      end
      
      MonitorCheck.find_or_create_by!(
        site_monitor: monitor,
        checked_at: check_time
      ) do |check|
        check.status_code = status_code == 0 ? nil : status_code
        check.response_time = response_time
        check.error_message = error_message
      end
    end
  end
  
  # Update monitor status based on latest check
  latest_check = monitor.monitor_checks.order(:checked_at).last
  if latest_check
    new_status = if latest_check.status_code.nil? || !latest_check.status_code.between?(200, 299)
      'down'
    else
      'up'
    end
    
    monitor.update!(
      status: new_status,
      last_checked_at: latest_check.checked_at
    )
  end
  
  puts "  ✅ Created #{monitor.monitor_checks.count} checks for #{monitor.name}"
end

# Create sample subscriptions for paid plans
companies.each do |company|
  next if company.plan_type == 'free'
  
  Subscription.find_or_create_by!(
    company: company,
    stripe_subscription_id: "sub_demo_#{SecureRandom.hex(8)}"
  ) do |sub|
    sub.plan_name = company.plan_type
    sub.status = 'active'
    sub.current_period_end = 1.month.from_now
  end
  puts "💳 Created subscription: #{company.name} - #{company.plan_type}"
end

puts "\n🎉 Seeding completed successfully!"
puts "\n📊 Summary:"
puts "  👥 #{Company.count} companies created"
puts "  🧑‍💼 #{User.count} users created"
puts "  🔍 #{SiteMonitor.count} monitors created"
puts "  📈 #{MonitorCheck.count} monitor checks created"
puts "  💳 #{Subscription.count} subscriptions created"

puts "\n🚀 You can now:"
puts "  • Sign in with any of the created users (password: 'password123')"
puts "  • View the dashboard with real monitoring data"
puts "  • Test the monitoring functionality"
puts "  • Explore billing features"

puts "\n👤 Sample login credentials:"
User.joins(:company).each do |user|
  puts "  #{user.email} (#{user.role}) - #{user.company.name} (#{user.company.plan_type})"
end
