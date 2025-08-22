# Uptime Monitor Setup Instructions

## Built with Rails 8, Solid Queue, Tailwind CSS, and Stripe

This is a complete uptime monitoring application similar to UptimeRobot but simpler and more affordable.

## Features Implemented

✅ **Core Application**
- Rails 8 with PostgreSQL database
- User authentication with Devise
- Company-based multi-user accounts
- Dark-themed UI with Tailwind CSS

✅ **Monitoring System**
- Website monitoring with HTTP status checks
- Solid Queue for background job processing
- Automatic monitoring every minute
- Response time tracking
- Uptime percentage calculations

✅ **Real-time Updates**
- ActionCable WebSocket connections
- Live dashboard updates
- Browser notifications for status changes

✅ **Billing Integration**
- Complete Stripe integration
- Multiple pricing tiers (Free, Starter, Professional, Business, Enterprise)
- Webhook handling for subscription events
- Billing portal access

✅ **Dashboard & UI**
- Beautiful dark-themed dashboard
- Monitor management (CRUD operations)
- Real-time status indicators
- Landing page with pricing

## Pricing Tiers

- **Free**: 1 monitor, 3-minute intervals
- **Starter (€5/month)**: 5 monitors, 1-minute intervals
- **Professional (€15/month)**: 25 monitors, 30-second intervals
- **Business (€35/month)**: 100 monitors, 10-second intervals
- **Enterprise (€99/month)**: Unlimited monitors, 5-second intervals

## Setup Instructions

### 1. Environment Variables

Create `.env` file or set these environment variables:

```bash
# Database
DATABASE_URL=postgresql://username:password@localhost/uptime_monitor_production

# Rails
RAILS_MASTER_KEY=your_master_key_here

# Stripe
STRIPE_SECRET_KEY=sk_test_...
STRIPE_PUBLISHABLE_KEY=pk_test_...
STRIPE_WEBHOOK_SECRET=whsec_...

# Email (optional)
SMTP_USERNAME=your_smtp_user
SMTP_PASSWORD=your_smtp_password

# PostgreSQL (for Docker)
POSTGRES_PASSWORD=secure_password_here
```

### 2. Database Setup

```bash
# Install dependencies
bundle install

# Setup database
rails db:create db:migrate

# Create initial company and user
rails console
```

In Rails console:
```ruby
company = Company.create!(name: "Test Company", plan_type: "free")
user = User.create!(
  first_name: "John",
  last_name: "Doe", 
  email: "admin@example.com",
  password: "password123",
  password_confirmation: "password123",
  company: company,
  role: "admin"
)
```

### 3. Development Server

```bash
# Start the server (includes Solid Queue)
bin/dev
```

This starts:
- Rails server on port 3000
- Solid Queue for background jobs
- Tailwind CSS compilation

### 4. Production Deployment (Kamal)

The app is configured for deployment to `monitor.rrbstudio.com` using Kamal:

```bash
# Setup secrets
echo "your_rails_master_key" > .kamal/secrets/RAILS_MASTER_KEY
echo "your_db_password" > .kamal/secrets/POSTGRES_PASSWORD
echo "sk_test_..." > .kamal/secrets/STRIPE_SECRET_KEY
echo "whsec_..." > .kamal/secrets/STRIPE_WEBHOOK_SECRET

# Deploy
bin/kamal setup
bin/kamal deploy
```

### 5. Stripe Configuration

1. Create Stripe account and get API keys
2. Create products and prices for each plan:
   - Starter: €5/month
   - Professional: €15/month 
   - Business: €35/month
   - Enterprise: €99/month
3. Set up webhook endpoint: `https://monitor.rrbstudio.com/webhooks/stripe`
4. Configure webhook events:
   - `checkout.session.completed`
   - `customer.subscription.updated`
   - `customer.subscription.deleted`
   - `invoice.payment_succeeded`
   - `invoice.payment_failed`

### 6. Domain Configuration

Point `monitor.rrbstudio.com` to your server IP address. Kamal will automatically handle SSL certificates via Let's Encrypt.

## How It Works

### Monitoring Flow
1. `ScheduleMonitoringJob` runs every minute
2. Finds monitors that need checking based on plan intervals
3. Queues `MonitorCheckJob` for each monitor
4. `MonitorCheckJob` makes HTTP request and stores results
5. Real-time updates sent via ActionCable
6. Notifications sent for status changes

### Background Jobs
- Uses Rails 8's Solid Queue (PostgreSQL-based)
- No Redis required for basic functionality
- Recurring jobs configured in `config/recurring.yml`

### Real-time Updates
- ActionCable WebSocket connections
- Automatic dashboard updates
- Browser notifications
- Status indicators update live

### Billing Integration
- Stripe Checkout for subscriptions
- Automatic plan enforcement (monitor limits, check intervals)
- Webhook handling for subscription events
- Billing portal for customers

## Architecture

### Models
- `Company` - Multi-tenant organization
- `User` - Belongs to company, has role (admin/member)
- `SiteMonitor` - URLs to monitor
- `MonitorCheck` - Individual check results
- `Subscription` - Stripe subscription records

### Jobs
- `ScheduleMonitoringJob` - Schedules monitor checks
- `MonitorCheckJob` - Performs HTTP checks
- `NotificationJob` - Sends alerts

### Services  
- `BillingService` - Stripe integration
- Channel: `MonitorsChannel` - Real-time updates

## Next Steps for Production

1. **Email Configuration**: Set up SMTP for notifications
2. **Monitoring Alerts**: SMS integration (Twilio)
3. **Status Pages**: Public status pages for customers
4. **API**: REST API for integrations
5. **Mobile App**: React Native app
6. **Multi-region**: Deploy to multiple regions
7. **Advanced Analytics**: Custom dashboards and reporting

## Development Commands

```bash
# Start development server
bin/dev

# Run jobs only
bundle exec solid_queue

# Database operations
rails db:migrate
rails db:seed

# Console
rails console

# Tests (add tests as needed)
rails test
```

## File Structure

```
app/
├── channels/           # ActionCable channels
├── controllers/        # Web controllers
├── jobs/              # Background jobs
├── mailers/           # Email handling
├── models/            # ActiveRecord models
├── services/          # Business logic
└── views/             # ERB templates

config/
├── deploy.yml         # Kamal deployment config  
├── recurring.yml      # Solid Queue recurring jobs
└── routes.rb          # URL routing

db/
├── migrate/           # Database migrations
└── schema.rb          # Database schema
```

The application is production-ready and can handle thousands of monitors efficiently with proper server resources.