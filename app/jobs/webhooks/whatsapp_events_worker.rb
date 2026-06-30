class Webhooks::WhatsappEventsWorker
  include Sidekiq::Job

  sidekiq_options queue: :low

  def perform(params = {})
    Webhooks::WhatsappEventsJob.perform_now(params.with_indifferent_access)
  end
end
