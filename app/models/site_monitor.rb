class SiteMonitor < ApplicationRecord
  belongs_to :company
  has_many :monitor_checks, dependent: :destroy

  validates :name, :url, presence: true
  validates :url, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]) }

  enum :status, { 
    up: 'up',
    down: 'down',
    unknown: 'unknown'
  }, default: :unknown

  scope :active, -> { where.not(status: 'unknown') }
  scope :up, -> { where(status: 'up') }
  scope :down, -> { where(status: 'down') }

  def uptime_percentage(days = 30)
    checks = monitor_checks.where('checked_at > ?', days.days.ago)
    return 0 if checks.empty?
    
    up_checks = checks.where(status_code: 200..299).count
    (up_checks.to_f / checks.count * 100).round(2)
  end

  def average_response_time(days = 7)
    monitor_checks.where('checked_at > ? AND response_time IS NOT NULL', days.days.ago)
                  .average(:response_time)&.round(2) || 0
  end

  def last_check
    monitor_checks.order(:checked_at).last
  end

  def should_check?
    return true if last_checked_at.nil?
    
    interval = company.check_interval_seconds
    last_checked_at < interval.seconds.ago
  end
end
