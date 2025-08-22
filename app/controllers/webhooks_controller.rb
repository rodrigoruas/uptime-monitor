class WebhooksController < ApplicationController
  skip_before_action :authenticate_user!
  skip_before_action :verify_authenticity_token

  def stripe
    payload = request.body.read
    sig_header = request.env['HTTP_STRIPE_SIGNATURE']
    endpoint_secret = ENV['STRIPE_WEBHOOK_SECRET']

    begin
      event = Stripe::Webhook.construct_event(payload, sig_header, endpoint_secret)
    rescue JSON::ParserError => e
      Rails.logger.error "Stripe webhook JSON parse error: #{e.message}"
      render json: { error: 'Invalid payload' }, status: 400
      return
    rescue Stripe::SignatureVerificationError => e
      Rails.logger.error "Stripe webhook signature verification error: #{e.message}"
      render json: { error: 'Invalid signature' }, status: 400
      return
    end

    case event['type']
    when 'checkout.session.completed'
      handle_checkout_session_completed(event['data']['object'])
    when 'customer.subscription.updated'
      handle_subscription_updated(event['data']['object'])
    when 'customer.subscription.deleted'
      handle_subscription_deleted(event['data']['object'])
    when 'invoice.payment_succeeded'
      handle_payment_succeeded(event['data']['object'])
    when 'invoice.payment_failed'
      handle_payment_failed(event['data']['object'])
    else
      Rails.logger.info "Unhandled Stripe event type: #{event['type']}"
    end

    render json: { status: 'success' }
  end

  private

  def handle_checkout_session_completed(session)
    company_id = session['metadata']['company_id']
    plan_type = session['metadata']['plan_type']
    
    return unless company_id && plan_type

    company = Company.find(company_id)
    subscription_id = session['subscription']
    
    if subscription_id
      stripe_subscription = Stripe::Subscription.retrieve(subscription_id)
      
      # Create or update subscription record
      subscription = company.subscriptions.find_or_initialize_by(
        stripe_subscription_id: subscription_id
      )
      
      subscription.update!(
        plan_name: plan_type,
        status: stripe_subscription.status,
        current_period_end: Time.at(stripe_subscription.current_period_end)
      )
      
      # Update company
      company.update!(
        plan_type: plan_type,
        subscription_status: stripe_subscription.status
      )
      
      Rails.logger.info "Subscription created for company #{company_id}: #{plan_type}"
    end
  end

  def handle_subscription_updated(subscription)
    company = find_company_by_customer(subscription['customer'])
    return unless company

    subscription_record = company.subscriptions.find_by(
      stripe_subscription_id: subscription['id']
    )
    
    if subscription_record
      subscription_record.update!(
        status: subscription['status'],
        current_period_end: Time.at(subscription['current_period_end'])
      )
      
      company.update!(subscription_status: subscription['status'])
      
      Rails.logger.info "Subscription updated for company #{company.id}: #{subscription['status']}"
    end
  end

  def handle_subscription_deleted(subscription)
    company = find_company_by_customer(subscription['customer'])
    return unless company

    subscription_record = company.subscriptions.find_by(
      stripe_subscription_id: subscription['id']
    )
    
    if subscription_record
      subscription_record.update!(status: 'canceled')
      company.update!(
        plan_type: 'free',
        subscription_status: 'canceled'
      )
      
      Rails.logger.info "Subscription canceled for company #{company.id}"
    end
  end

  def handle_payment_succeeded(invoice)
    company = find_company_by_customer(invoice['customer'])
    return unless company

    Rails.logger.info "Payment succeeded for company #{company.id}: #{invoice['amount_paid'] / 100.0} #{invoice['currency'].upcase}"
  end

  def handle_payment_failed(invoice)
    company = find_company_by_customer(invoice['customer'])
    return unless company

    company.update!(subscription_status: 'past_due')
    
    Rails.logger.warn "Payment failed for company #{company.id}"
    
    # Send payment failure notification
    company.users.each do |user|
      # MonitorMailer.payment_failed(user, company).deliver_now
    end
  end

  def find_company_by_customer(customer_id)
    Company.find_by(stripe_customer_id: customer_id)
  end
end