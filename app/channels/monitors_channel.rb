class MonitorsChannel < ApplicationCable::Channel
  def subscribed
    # Stream for the current user's company monitors
    company = current_user&.company
    if company
      stream_from "monitors_#{company.id}"
      Rails.logger.info "User #{current_user.id} subscribed to monitors_#{company.id}"
    else
      reject
    end
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
    Rails.logger.info "User #{current_user&.id} unsubscribed from monitors channel"
  end
end