require 'rails_helper'

RSpec.describe Expenses::Updater do
  let(:category) { create(:category) }
  let(:expense) { create(:expense, category: category, amount: 10.00) }

  it "updates a valid expense" do
    result = described_class.new(expense, { amount: 25.00 }).call

    expect(result.success?).to be true
    expect(result.data.amount).to eq(25.00)
    expect(result.errors).to be_nil
  end

  it "returns errors instead of raising for an invalid update" do
    result = described_class.new(expense, { date: 1.day.from_now }).call

    expect(result.success?).to be false
    expect(result.errors).to include("Date can't be in the future")
    expect(expense.reload.amount).to eq(10.00)
  end
end
