# OPENSF: read/update agent profile settings (admin can target any user via ?user_id=)
class Api::V1::Accounts::Opensf::AgentProfilesController < Api::V1::Accounts::BaseController
  def show
    profile = OpensfAgentProfile.find_or_initialize_by(user: target_user)
    render json: { codigo_corretor: profile.codigo_corretor }
  end

  def update
    profile = OpensfAgentProfile.find_or_initialize_by(user: target_user)
    profile.codigo_corretor = params[:codigo_corretor].to_s.strip
    profile.save!
    render json: { codigo_corretor: profile.codigo_corretor }
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  def target_user
    if params[:user_id].present? && current_user.administrator?
      User.find(params[:user_id])
    else
      current_user
    end
  end
end
