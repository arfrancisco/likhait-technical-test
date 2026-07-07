class Expense < ApplicationRecord
  belongs_to :category

  # You can't have spent money on a date that hasn't happened yet.
  validates :date, comparison: { less_than_or_equal_to: -> { Date.current }, message: "can't be in the future" }
end
