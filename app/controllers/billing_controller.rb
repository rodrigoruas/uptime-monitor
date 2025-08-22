class BillingController < ApplicationController
  before_action :set_billing_service

  def index
    @current_subscription = @current_company.subscriptions.active.first
    @plans = plans_data
  end

  def create
    plan_type = params[:plan_type]
    
    if plan_type == 'free'
      @current_company.update!(plan_type: 'free', subscription_status: 'inactive')
      redirect_to billing_index_path, notice: 'Switched to free plan successfully.'
      return
    end

    begin
      success_url = billing_index_url + '?success=true'
      cancel_url = billing_index_url + '?canceled=true'
      
      session = @billing_service.create_checkout_session(
        plan_type,
        success_url,
        cancel_url
      )
      
      redirect_to session.url, allow_other_host: true
    rescue => e
      Rails.logger.error "Billing error: #{e.message}"
      redirect_to billing_index_path, alert: 'Unable to process subscription. Please try again.'
    end
  end

  def portal
    begin
      return_url = billing_index_url
      session = @billing_service.create_billing_portal_session(return_url)
      redirect_to session.url, allow_other_host: true
    rescue => e
      Rails.logger.error "Billing portal error: #{e.message}"
      redirect_to billing_index_path, alert: 'Unable to access billing portal. Please try again.'
    end
  end

  private

  def set_billing_service
    @billing_service = BillingService.new(@current_company)
  end

  def plans_data
    [
      {
        name: 'Free',
        type: 'free',
        price: 0,
        currency: '€',
        period: 'forever',
        monitors: 1,
        interval: '3 minutes',
        features: ['Email notifications', '30-day data retention']
      },
      {
        name: 'Starter',
        type: 'starter',
        price: 5,
        currency: '€',
        period: 'month',
        monitors: 5,
        interval: '1 minute',
        features: ['Email & SMS notifications', '90-day data retention', 'Multi-user support (3 users)']
      },
      {
        name: 'Professional',
        type: 'professional',
        price: 15,
        currency: '€',
        period: 'month',
        monitors: 25,
        interval: '30 seconds',
        features: ['All notification types', '1-year data retention', 'Multi-user support (10 users)', 'API access']
      },
      {
        name: 'Business',
        type: 'business',
        price: 35,
        currency: '€',
        period: 'month',
        monitors: 100,
        interval: '10 seconds',
        features: ['All features', 'Unlimited data retention', 'Unlimited users', 'Custom status pages', 'Priority support']
      },
      {
        name: 'Enterprise',
        type: 'enterprise',
        price: 99,
        currency: '€',
        period: 'month',
        monitors: 'Unlimited',
        interval: '5 seconds',
        features: ['All features', 'White-label options', 'Dedicated support', 'Custom integrations']
      }
    ]
  end
end
