require 'rails_helper'

RSpec.describe Expense, type: :model do
  it "is valid with today's date" do
    expense = build(:expense, date: Date.current)

    expect(expense).to be_valid
  end

  it "is valid with a past date" do
    expense = build(:expense, date: 1.year.ago.to_date)

    expect(expense).to be_valid
  end

  it "is invalid with a future date" do
    expense = build(:expense, date: 1.day.from_now.to_date)

    expect(expense).not_to be_valid
    expect(expense.errors[:date]).to include("can't be in the future")
  end
end
