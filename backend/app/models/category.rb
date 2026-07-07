class Category < ApplicationRecord
  has_many :expenses, dependent: :destroy

  # The DB already has a unique index on name, but without this validation a
  # duplicate name blows up as an unhandled 500 (StatementInvalid) instead of
  # a normal 422 with an error message the frontend can show.
  validates :name, presence: true, uniqueness: true
end
