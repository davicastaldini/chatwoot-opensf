module Opensf
  class PropostaCorbee < ActiveRecord::Base
    # OPENSF: read-only connection to external corbee database — never write
    establish_connection(
      adapter: 'postgresql',
      host: ENV.fetch('CORBEE_DB_HOST', '72.60.243.153'),
      port: ENV.fetch('CORBEE_DB_PORT', 5432).to_i,
      database: ENV.fetch('CORBEE_DB_NAME', 'postgres'),
      username: ENV.fetch('CORBEE_DB_USER', 'postgres'),
      password: ENV.fetch('CORBEE_DB_PASSWORD', ''),
      pool: 2,
      connect_timeout: 5
    )

    self.table_name = 'propostas_corbee'

    def readonly?
      true
    end
  end
end
