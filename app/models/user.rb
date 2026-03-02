class User < ApplicationRecord
  rolify
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # Associations
  has_many :scouting_entries, dependent: :destroy
  has_many :pick_lists, dependent: :destroy

  # Validations
  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :team_number, presence: true

  # Scopes
  scope :scouts, -> { joins(:roles).where(roles: { name: "scout" }) }

  # Returns "First Last"
  def full_name
    "#{first_name} #{last_name}"
  end

  # Returns the highest-priority role name.
  # Priority order: admin > lead > analyst > scout
  ROLE_PRIORITY = %w[admin lead analyst scout].freeze

  def role_name
    ROLE_PRIORITY.find { |r| has_role?(r) } || "scout"
  end
end
