class Company < ApplicationRecord
  has_many :users, dependent: :destroy
  has_many :site_monitors, dependent: :destroy
  has_many :subscriptions, dependent: :destroy

  validates :name, presence: true

  enum :plan_type, { 
    free: 'free',
    starter: 'starter', 
    professional: 'professional',
    business: 'business',
    enterprise: 'enterprise'
  }, default: :free

  enum :subscription_status, { 
    active: 'active',
    inactive: 'inactive',
    past_due: 'past_due',
    canceled: 'canceled'
  }, default: :inactive

  def monitor_limit
    case plan_type
    when 'free' then 1
    when 'starter' then 5
    when 'professional' then 25
    when 'business' then 100
    when 'enterprise' then Float::INFINITY
    else 1
    end
  end

  def check_interval_seconds
    case plan_type
    when 'free' then 180 # 3 minutes
    when 'starter' then 60 # 1 minute
    when 'professional' then 30 # 30 seconds
    when 'business' then 10 # 10 seconds
    when 'enterprise' then 5 # 5 seconds
    else 180
    end
  end
end
