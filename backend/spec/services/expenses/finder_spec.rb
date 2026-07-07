require 'rails_helper'

RSpec.describe Expenses::Finder do
  let(:category) { create(:category) }

  it "orders by date descending by default" do
    older = create(:expense, category: category, date: 2.days.ago.to_date, created_at: 1.day.ago)
    newer = create(:expense, category: category, date: 1.day.ago.to_date, created_at: 2.days.ago)

    result = described_class.new({}).call

    expect(result.map(&:id)).to eq([ newer.id, older.id ])
  end

  it "orders by created_at when explicitly requested" do
    older_by_date = create(:expense, category: category, date: 2.days.ago.to_date, created_at: 1.day.ago)
    newer_by_date = create(:expense, category: category, date: 1.day.ago.to_date, created_at: 2.days.ago)

    result = described_class.new(order_by: "created_at").call

    expect(result.map(&:id)).to eq([ older_by_date.id, newer_by_date.id ])
  end

  it "falls back to date ordering for an unrecognized order_by value" do
    older = create(:expense, category: category, date: 2.days.ago.to_date, created_at: 1.day.ago)
    newer = create(:expense, category: category, date: 1.day.ago.to_date, created_at: 2.days.ago)

    result = described_class.new(order_by: "amount").call

    expect(result.map(&:id)).to eq([ newer.id, older.id ])
  end

  it "filters to the given year and month by date" do
    in_month = create(:expense, category: category, date: Date.new(2026, 3, 15))
    other_month = create(:expense, category: category, date: Date.new(2026, 4, 1))

    result = described_class.new(year: "2026", month: "3").call

    expect(result.map(&:id)).to eq([ in_month.id ])
    expect(result.map(&:id)).not_to include(other_month.id)
  end
end
