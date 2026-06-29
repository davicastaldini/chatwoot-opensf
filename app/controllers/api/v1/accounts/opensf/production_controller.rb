# OPENSF: production KPI report for the logged-in agent, querying Corbee read-only DB
class Api::V1::Accounts::Opensf::ProductionController < Api::V1::Accounts::BaseController
  def kpis
    profile = OpensdfAgentProfile.find_by(user: current_user)
    codigo = profile&.codigo_corretor.to_s.strip

    return render json: { error: 'codigo_corretor nao configurado' }, status: :unprocessable_entity if codigo.blank?

    data = corbee_kpis(codigo)
    render json: data
  rescue PG::Error => e
    Rails.logger.error "[OPENSF] production kpi error: #{e.message}"
    render json: { error: 'erro ao consultar producao' }, status: :service_unavailable
  end

  private

  PAID_STATUSES = ['Pago pelo Banco', 'Averbada'].freeze

  def corbee_kpis(codigo)
    conn = corbee_connection
    mes_inicio = Date.today.beginning_of_month.to_s
    mes_fim    = Date.today.end_of_month.to_s

    # Main aggregation for current month
    result = conn.exec_params(<<~SQL, [codigo, mes_inicio, mes_fim, *PAID_STATUSES])
      SELECT
        COUNT(*)                                                         AS total_propostas,
        COALESCE(SUM(valor_producao), 0)                                AS producao_total,
        COALESCE(SUM(valor_liquido), 0)                                 AS valor_liquido_total,
        COUNT(*) FILTER (WHERE desc_status_proposta = ANY($4::text[]))  AS pagas_count,
        COALESCE(
          SUM(valor_producao) FILTER (WHERE desc_status_proposta = ANY($4::text[])), 0
        )                                                               AS pagas_valor
      FROM public.propostas_corbee
      WHERE codigo_corretor::text = $1
        AND data_proposta >= $2
        AND data_proposta <= $3
    SQL

    row = result[0]
    total = row['total_propostas'].to_i
    producao_total = row['producao_total'].to_f
    pagas_count = row['pagas_count'].to_i
    pagas_valor = row['pagas_valor'].to_f

    ticket_medio = total > 0 ? producao_total / total : 0.0
    percent_pagas = total > 0 ? (pagas_count.to_f / total * 100).round(2) : 0.0
    projecao = calcular_projecao(pagas_valor)

    {
      total_propostas: total,
      ticket_medio: ticket_medio.round(2),
      producao_total: producao_total.round(2),
      valor_liquido_total: row['valor_liquido_total'].to_f.round(2),
      pagas_count: pagas_count,
      pagas_valor: pagas_valor.round(2),
      percent_pagas: percent_pagas,
      projecao: projecao,
      mes_referencia: Date.today.strftime('%m/%Y')
    }
  ensure
    conn&.finish
  end

  def calcular_projecao(valor_pago)
    hoje = Date.today
    dias_uteis_decorridos = business_days_until(hoje.beginning_of_month, hoje)
    dias_uteis_mes = business_days_until(hoje.beginning_of_month, hoje.end_of_month)
    return 0.0 if dias_uteis_decorridos.zero?

    (valor_pago / dias_uteis_decorridos * dias_uteis_mes).round(2)
  end

  def business_days_until(from, to)
    (from..to).count { |d| d.wday.between?(1, 5) }
  end

  def corbee_connection
    PG.connect(
      host:            ENV.fetch('CORBEE_DB_HOST', '72.60.243.153'),
      port:            ENV.fetch('CORBEE_DB_PORT', '5432').to_i,
      dbname:          ENV.fetch('CORBEE_DB_NAME', 'postgres'),
      user:            ENV.fetch('CORBEE_DB_USER', 'postgres'),
      password:        ENV.fetch('CORBEE_DB_PASSWORD', ''),
      connect_timeout: 5
    )
  end
end
