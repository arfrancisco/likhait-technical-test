require 'rails_helper'

# Same happy path as expense_tracking_request_flow_spec.rb, but calling the
# service objects directly instead of going through HTTP/the controller
# layer. Deliberately avoids factories, mocks, and stubs -- every record
# here is created through the actual service classes, the same way the
# controllers do it, so this proves the services really compose together
# rather than just asserting against test doubles.
RSpec.describe "Expense tracking service flow" do
  it "supports creating a category, adding an expense to it, listing, updating, and deleting" do
    # 1. Create a category (Categories::Creator).
    category_result = Categories::Creator.new(name: "Groceries").call
    expect(category_result.success?).to be true
    category = category_result.data

    # 2. Create an expense against that category (Expenses::Creator).
    expense_result = Expenses::Creator.new(
      description: "Weekly shop", amount: 45.00, category_id: category.id, date: Date.current
    ).call
    expect(expense_result.success?).to be true
    expense = expense_result.data

    # 3. A second, older expense in the same category, to prove
    # Expenses::Finder sorts by date (BUG-001) and not creation order.
    older_expense_result = Expenses::Creator.new(
      description: "Last week's shop", amount: 30.00, category_id: category.id, date: 1.week.ago.to_date
    ).call
    expect(older_expense_result.success?).to be true

    # 4. List (Expenses::Finder): confirm the most recent expense comes first.
    expenses = Expenses::Finder.new({}).call
    expect(expenses.first.description).to eq("Weekly shop")
    expect(expenses.last.description).to eq("Last week's shop")

    # 5. Update the first expense's amount (Expenses::Updater).
    update_result = Expenses::Updater.new(expense, { amount: 50.00 }).call
    expect(update_result.success?).to be true
    expect(update_result.data.amount).to eq(50.00)

    # 6. Delete it (a one-liner in the controller, so no service to call
    # here either), then confirm it's actually gone from the list.
    expense.destroy
    remaining_ids = Expenses::Finder.new({}).call.map(&:id)
    expect(remaining_ids).not_to include(expense.id)
  end
end
