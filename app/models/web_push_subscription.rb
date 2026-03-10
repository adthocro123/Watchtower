class WebPushSubscription < ApplicationRecord
  # Associations
  belongs_to :user

  # Validations
  validates :endpoint, presence: true, uniqueness: true
  validates :p256dh, presence: true
  validates :auth, presence: true
end
