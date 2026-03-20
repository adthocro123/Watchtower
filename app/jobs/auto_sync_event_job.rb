# frozen_string_literal: true

class AutoSyncEventJob < ApplicationJob
  queue_as :default
  retry_on StandardError, wait: :polynomially_longer, attempts: 2

  # Runs TBA sync and downstream jobs asynchronously after dashboard load.
  def perform(event_id)
    event = Event.find_by(id: event_id)
    return unless event

    TbaSyncService.new(event.tba_key).sync_matches! if event.tba_key.present? && TbaClient.configured?

    RefreshSummariesJob.perform_later(event.id)
    SyncStatboticsJob.perform_later(event.id)
    RefreshPredictionsJob.perform_later(event.id)

    Rails.logger.info("[AutoSyncEventJob] Enqueued downstream sync for event #{event.tba_key}")
  end
end
