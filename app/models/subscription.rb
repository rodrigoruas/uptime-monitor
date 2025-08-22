class Subscription < ApplicationRecord
  belongs_to :company

  validates :plan_name, presence: true

  enum :status, { 
    active: 'active',
    past_due: 'past_due',
    canceled: 'canceled',
    unpaid: 'unpaid'
  }

  scope :active, -> { where(status: 'active') }

  def active?
    status == 'active' && current_period_end > Time.current
  end

  def expired?
    current_period_end < Time.current
  end
end
