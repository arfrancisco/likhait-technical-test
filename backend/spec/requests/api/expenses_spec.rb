require 'rails_helper'

RSpec.describe "Api::Expenses", type: :request do
  let!(:food_category) { Category.create!(name: "Food") }
  let!(:transport_category) { Category.create!(name: "Transport") }

  describe "GET /api/expenses" do
    # expense1/expense2 deliberately have date and created_at pointing in
    # opposite directions, so a test asserting "ordered by date" can't
    # accidentally pass just because it also happens to match created_at order.
    let!(:expense1) do
      Expense.create!(description: "Lunch", amount: 100.00, category: food_category, date: 2.days.ago.to_date, created_at: 1.day.ago)
    end
    let!(:expense2) do
      Expense.create!(description: "Taxi", amount: 50.00, category: transport_category, date: 1.day.ago.to_date, created_at: 2.days.ago)
    end

    it "returns all expenses with category information" do
      get "/api/expenses"

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json.length).to eq(2)
    end

    it "returns expenses in descending order by date by default" do
      get "/api/expenses"

      json = JSON.parse(response.body)
      # expense2's date is more recent even though it was created earlier --
      # proves the default sort is on date, not created_at (BUG-001).
      expect(json.first["id"]).to eq(expense2.id)
      expect(json.last["id"]).to eq(expense1.id)
    end

    it "orders by created_at when explicitly requested via order_by" do
      get "/api/expenses", params: { order_by: "created_at" }

      json = JSON.parse(response.body)
      expect(json.first["id"]).to eq(expense1.id)
      expect(json.last["id"]).to eq(expense2.id)
    end

    it "falls back to date ordering for an unrecognized order_by value" do
      get "/api/expenses", params: { order_by: "amount" }

      json = JSON.parse(response.body)
      expect(json.first["id"]).to eq(expense2.id)
      expect(json.last["id"]).to eq(expense1.id)
    end
  end

  describe "POST /api/expenses" do
    context "with valid parameters" do
      let(:valid_params) do
        {
          expense: {
            description: "Team Lunch",
            amount: 150.50,
            category_id: food_category.id,
            date: Date.today
          }
        }
      end

      it "creates a new expense" do
        expect {
          post "/api/expenses", params: valid_params, as: :json
        }.to change(Expense, :count).by(1)

        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)
        expect(json["description"]).to eq("Team Lunch")
        expect(json["amount"]).to eq("150.5")
      end
    end

    context "with invalid parameters" do
      it "with negative amounts" do
        invalid_params = {
          expense: {
            description: "Invalid expense",
            amount: -100.00,
            category_id: food_category.id,
            date: Date.today
          }
        }

        expect {
          post "/api/expenses", params: invalid_params, as: :json
        }.to change(Expense, :count).by(1)

        expect(response).to have_http_status(:created)
      end

      it "with empty descriptions" do
        invalid_params = {
          expense: {
            description: "",
            amount: 100.00,
            category_id: food_category.id,
            date: Date.today
          }
        }

        expect {
          post "/api/expenses", params: invalid_params, as: :json
        }.to change(Expense, :count).by(1)

        expect(response).to have_http_status(:created)
      end

      it "with a future date" do
        invalid_params = {
          expense: {
            description: "Time traveler's expense",
            amount: 100.00,
            category_id: food_category.id,
            date: 1.day.from_now.to_date
          }
        }

        expect {
          post "/api/expenses", params: invalid_params, as: :json
        }.not_to change(Expense, :count)

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json["errors"]).to include("Date can't be in the future")
      end
    end
  end
end
