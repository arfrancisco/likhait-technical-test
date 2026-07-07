require 'rails_helper'

RSpec.describe Expenses::Creator do
  let(:category) { create(:category) }

  it "creates a valid expense" do
    result = described_class.new(
      description: "Lunch", amount: 12.50, date: Date.current, category_id: category.id
    ).call

    expect(result.success?).to be true
    expect(result.data).to be_persisted
    expect(result.errors).to be_nil
  end

  it "returns errors instead of raising for an invalid expense" do
    result = described_class.new(
      description: "Time traveler's lunch", amount: 12.50, date: 1.day.from_now, category_id: category.id
    ).call

    expect(result.success?).to be false
    expect(result.data).to be_nil
    expect(result.errors).to include("Date can't be in the future")
  end
end
