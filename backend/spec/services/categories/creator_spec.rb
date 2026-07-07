require 'rails_helper'

RSpec.describe Categories::Creator do
  it "creates a valid category" do
    result = described_class.new(name: "Groceries").call

    expect(result.success?).to be true
    expect(result.data).to be_persisted
    expect(result.errors).to be_nil
  end

  it "returns errors instead of raising for a duplicate name" do
    create(:category, name: "Groceries")

    result = described_class.new(name: "Groceries").call

    expect(result.success?).to be false
    expect(result.data).to be_nil
    expect(result.errors).to include("Name has already been taken")
  end
end
