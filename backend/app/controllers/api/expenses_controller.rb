class Api::ExpensesController < ApplicationController
  # Only these columns can be sorted on. BUG-001: expenses were always ordered by
  # created_at, so newly added expenses (backdated or not) didn't surface at the
  # top of the list. Default to `date` since that's what users actually expect
  # "most recent" to mean, but keep the column selectable via `order_by` for
  # future callers instead of hardcoding it.
  SORTABLE_COLUMNS = %w[date created_at].freeze

  def index
    expenses = Expense.includes(:category).order(order_column => :desc)

    if params[:year].present? && params[:month].present?
      year = params[:year].to_i
      month = params[:month].to_i

      start_date = Date.new(year, month, 1)
      end_date = start_date.end_of_month

      # Filter on `date` (the expense's actual date), not `created_at` (when the
      # record was saved) -- same underlying bug as the ordering above.
      expenses = expenses.where(date: start_date..end_date)
    end

    render json: expenses.map { |expense| format_expense(expense) }
  end

  def create
    expense = Expense.new(expense_params)

    if expense.save
      render json: format_expense(expense), status: :created
    else
      render json: { errors: expense.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    expense = Expense.find(params[:id])

    if expense.update(expense_params)
      render json: format_expense(expense)
    else
      render json: { errors: expense.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    expense = Expense.find(params[:id])
    expense.destroy
    head :no_content
  end

  private

  # Falls back to `date` for anything not on the whitelist, so an arbitrary
  # column can never reach `order()` (params[:order_by] is user input).
  def order_column
    SORTABLE_COLUMNS.include?(params[:order_by]) ? params[:order_by] : "date"
  end

  def expense_params
    params.require(:expense).permit(:description, :amount, :category_id, :date)
  end

  def format_expense(expense)
    {
      id: expense.id,
      description: expense.description,
      amount: expense.amount.to_f,
      category: expense.category.name,
      date: expense.date.to_s,
      created_at: expense.created_at,
      updated_at: expense.updated_at
    }
  end
end
