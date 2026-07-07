class Api::ExpensesController < ApplicationController
  # Controller just wires params -> service -> render; the filter/sort logic
  # (Expenses::Finder) and the save/validate logic (Expenses::Creator,
  # Expenses::Updater) live in app/services so they're testable on their own.
  def index
    expenses = Expenses::Finder.new(params).call
    render json: expenses.map { |expense| format_expense(expense) }
  end

  def create
    result = Expenses::Creator.new(expense_params).call

    if result.success?
      render json: format_expense(result.data), status: :created
    else
      render json: { errors: result.errors }, status: :unprocessable_entity
    end
  end

  def update
    expense = Expense.find(params[:id])
    result = Expenses::Updater.new(expense, expense_params).call

    if result.success?
      render json: format_expense(result.data)
    else
      render json: { errors: result.errors }, status: :unprocessable_entity
    end
  end

  def destroy
    expense = Expense.find(params[:id])
    expense.destroy
    head :no_content
  end

  private

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
