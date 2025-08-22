class MonitorCheck < ApplicationRecord
  belongs_to :site_monitor

  validates :checked_at, presence: true

  scope :successful, -> { where(status_code: 200..299) }
  scope :failed, -> { where.not(status_code: 200..299) }
  scope :recent, -> { order(checked_at: :desc) }

  def success?
    status_code&.between?(200, 299)
  end

  def status_text
    case status_code
    when 200..299 then 'UP'
    when 300..399 then 'REDIRECT'
    when 400..499 then 'CLIENT ERROR'
    when 500..599 then 'SERVER ERROR'
    else 'UNKNOWN'
    end
  end
end
