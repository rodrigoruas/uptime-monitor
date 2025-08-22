module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
    end

    private

    def find_verified_user
      # Get user from cookies (Devise session)
      if session_user_id = request.session[:user_id] || cookies.encrypted[:user_id]
        user = User.find_by(id: session_user_id)
        return user if user
      end

      # Try to get from Warden (Devise)
      if request.env['warden']&.authenticated?
        return request.env['warden'].user
      end

      reject_unauthorized_connection
    end
  end
end