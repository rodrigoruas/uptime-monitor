class BillingService
  STRIPE_PLANS = {
    'starter' => ENV.fetch('STRIPE_STARTER_PRICE_ID', 'price_starter'),
    'professional' => ENV.fetch('STRIPE_PROFESSIONAL_PRICE_ID', 'price_professional'),
    'business' => ENV.fetch('STRIPE_BUSINESS_PRICE_ID', 'price_business'),
    'enterprise' => ENV.fetch('STRIPE_ENTERPRISE_PRICE_ID', 'price_enterprise')
  }.freeze

  def initialize(company)
    @company = company
    Stripe.api_key = ENV.fetch('STRIPE_SECRET_KEY')
  end

  def create_customer
    return if @company.stripe_customer_id.present?

    customer = Stripe::Customer.create(
      email: @company.users.first&.email,
      name: @company.name,
      metadata: {
        company_id: @company.id
      }
    )

    @company.update!(stripe_customer_id: customer.id)
    customer
  end

  def create_subscription(plan_type)
    customer = ensure_customer
    price_id = STRIPE_PLANS[plan_type]

    raise ArgumentError, "Invalid plan type: #{plan_type}" unless price_id

    subscription = Stripe::Subscription.create(
      customer: customer.id,
      items: [{ price: price_id }],
      metadata: {
        company_id: @company.id,
        plan_type: plan_type
      }
    )

    # Create or update subscription record
    subscription_record = @company.subscriptions.find_or_initialize_by(
      stripe_subscription_id: subscription.id
    )
    
    subscription_record.update!(
      plan_name: plan_type,
      status: subscription.status,
      current_period_end: Time.at(subscription.current_period_end)
    )

    # Update company plan
    @company.update!(
      plan_type: plan_type,
      subscription_status: subscription.status
    )

    subscription
  end

  def cancel_subscription
    return unless @company.subscriptions.active.exists?

    active_subscription = @company.subscriptions.active.first
    
    stripe_subscription = Stripe::Subscription.retrieve(
      active_subscription.stripe_subscription_id
    )
    
    cancelled_subscription = Stripe::Subscription.modify(
      stripe_subscription.id,
      cancel_at_period_end: true
    )

    active_subscription.update!(status: 'canceled')
    @company.update!(subscription_status: 'canceled')

    cancelled_subscription
  end

  def create_billing_portal_session(return_url)
    customer = ensure_customer
    
    Stripe::BillingPortal::Session.create(
      customer: customer.id,
      return_url: return_url
    )
  end

  def create_checkout_session(plan_type, success_url, cancel_url)
    customer = ensure_customer
    price_id = STRIPE_PLANS[plan_type]

    raise ArgumentError, "Invalid plan type: #{plan_type}" unless price_id

    Stripe::Checkout::Session.create(
      customer: customer.id,
      payment_method_types: ['card'],
      line_items: [{
        price: price_id,
        quantity: 1
      }],
      mode: 'subscription',
      success_url: success_url,
      cancel_url: cancel_url,
      metadata: {
        company_id: @company.id,
        plan_type: plan_type
      }
    )
  end

  private

  def ensure_customer
    if @company.stripe_customer_id.present?
      Stripe::Customer.retrieve(@company.stripe_customer_id)
    else
      create_customer
    end
  end
end