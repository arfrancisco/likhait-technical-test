class AddIndexOnExpensesDate < ActiveRecord::Migration[7.2]
  def change
    # The original (pre-Rails) schema indexed expenses.created_at to support
    # sorting/filtering the list. Since BUG-001 moved that sort/filter to
    # `date`, that's the column worth indexing now -- there wasn't one at all.
    add_index :expenses, :date
  end
end
