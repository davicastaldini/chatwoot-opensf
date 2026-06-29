# OPENSF: read/update the logged-in agent's profile settings
class Api::V1::Accounts::Opensf::AgentProfilesController < Api::V1::Accounts::BaseController
  def show
    profile = OpensfAgentProfile.find_or_initialize_by(user: current_user)
    render json: { codigo_corretor: profile.codigo_corretor }
  end

  def update
    profile = OpensfAgentProfile.find_or_initialize_by(user: current_user)
    profile.codigo_corretor = params[:codigo_corretor].to_s.strip
    profile.save!
    render json: { codigo_corretor: profile.codigo_corretor }
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: e.message }, status: :unprocessable_entity
  end
end
