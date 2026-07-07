require 'rails_helper'

# There was previously no test anywhere that exercised the app as a whole --
# expenses_spec.rb and categories_spec.rb each test one resource in
# isolation. This walks the full happy path through real HTTP-style
# requests + the DB, exercising the services added in this PR together.
RSpec.describe "Expense tracking flow", type: :request do
  it "supports creating a category, adding an expense to it, listing, updating, and deleting" do
    post "/api/categories", params: { category: { name: "Groceries" } }, as: :json
    expect(response).to have_http_status(:created)
    category_id = JSON.parse(response.body)["id"]

    post "/api/expenses", params: {
      expense: { description: "Weekly shop", amount: 45.00, category_id: category_id, date: Date.current }
    }, as: :json
    expect(response).to have_http_status(:created)
    expense_id = JSON.parse(response.body)["id"]

    # An older expense in the same category, to prove the list is sorted by
    # date (BUG-001) and not creation order.
    post "/api/expenses", params: {
      expense: { description: "Last week's shop", amount: 30.00, category_id: category_id, date: 1.week.ago.to_date }
    }, as: :json
    expect(response).to have_http_status(:created)

    get "/api/expenses"
    json = JSON.parse(response.body)
    expect(json.first["description"]).to eq("Weekly shop")
    expect(json.last["description"]).to eq("Last week's shop")

    put "/api/expenses/#{expense_id}", params: { expense: { amount: 50.00 } }, as: :json
    expect(response).to have_http_status(:success)
    expect(JSON.parse(response.body)["amount"]).to eq(50.0)

    delete "/api/expenses/#{expense_id}"
    expect(response).to have_http_status(:no_content)

    get "/api/expenses"
    remaining_ids = JSON.parse(response.body).map { |expense| expense["id"] }
    expect(remaining_ids).not_to include(expense_id)
  end
end
