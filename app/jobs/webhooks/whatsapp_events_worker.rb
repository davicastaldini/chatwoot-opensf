class Webhooks::WhatsappEventsWorker
  include Sidekiq::Job

  sidekiq_options queue: :whatsapp_webhooks

  def perform(params = {})
    Webhooks::WhatsappEventsJob.perform_now(params.with_indifferent_access)
  end
end
