class Api::V1::Accounts::Opensf::ProposalsController < Api::V1::Accounts::BaseController
  # OPENSF: read-only endpoint — skip token auth (iframe can't pass headers easily)
  skip_before_action :authenticate_user!, raise: false
  skip_before_action :authenticate_access_token!, raise: false
  skip_before_action :validate_bot_access_token!, raise: false
  CORBEE_FIELDS = %w[
    id codigo_proposta_webcred codigo_proposta_banco nome_cliente cpf_cliente
    banco produto convenio valor_liquido valor_producao valor_parcelas
    data_proposta data_averbacao data_pagamento_banco
    desc_status_proposta status_banco cor_status_banco operacao data_nascimento
  ].freeze

  def index
    cpf = params[:cpf].to_s.gsub(/\D/, '')
    return render json: { error: 'cpf obrigatorio' }, status: :bad_request if cpf.blank?

    rows = corbee_query(cpf)
    render json: rows
  rescue PG::Error => e
    Rails.logger.error "[OPENSF] corbee query error: #{e.message}"
    render json: { error: 'erro ao consultar propostas' }, status: :service_unavailable
  end

  private

  def corbee_query(cpf)
    conn = PG.connect(
      host: ENV.fetch('CORBEE_DB_HOST', '72.60.243.153'),
      port: ENV.fetch('CORBEE_DB_PORT', '5432').to_i,
      dbname: ENV.fetch('CORBEE_DB_NAME', 'postgres'),
      user: ENV.fetch('CORBEE_DB_USER', 'postgres'),
      password: ENV.fetch('CORBEE_DB_PASSWORD', ''),
      connect_timeout: 5
    )

    result = conn.exec_params(
      <<~SQL,
        SELECT #{CORBEE_FIELDS.join(', ')}
        FROM public.propostas_corbee
        WHERE REGEXP_REPLACE(COALESCE(cpf_cliente, ''), '[^0-9]', '', 'g') = $1
        ORDER BY data_proposta DESC NULLS LAST
        LIMIT 50
      SQL
      [cpf]
    )

    result.map(&:to_h)
  ensure
    conn&.finish
  end
end
