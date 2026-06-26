class Api::V1::Accounts::Opensf::ProposalsController < Api::V1::Accounts::BaseController
  # OPENSF: returns proposals from external corbee DB filtered by CPF — read only
  def index
    cpf = params[:cpf].to_s.gsub(/\D/, '')
    return render json: { error: 'cpf obrigatorio' }, status: :bad_request if cpf.blank?

    proposals = Opensf::PropostaCorbee
                  .where('REGEXP_REPLACE(cpf_cliente, \'[^0-9]\', \'\', \'g\') = ?', cpf)
                  .order(data_proposta: :desc)
                  .limit(50)
                  .select(:id, :codigo_proposta_webcred, :codigo_proposta_banco,
                          :nome_cliente, :cpf_cliente, :banco, :produto, :convenio,
                          :valor_liquido, :valor_producao, :valor_parcelas,
                          :data_proposta, :data_averbacao, :data_pagamento_banco,
                          :desc_status_proposta, :status_banco, :cor_status_banco,
                          :operacao, :data_nascimento)

    render json: proposals
  rescue StandardError => e
    Rails.logger.error "[OPENSF] proposals fetch error: #{e.message}"
    render json: { error: 'erro ao consultar propostas' }, status: :service_unavailable
  end
end
