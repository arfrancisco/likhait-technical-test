module Expenses
  # Builds the expense list for GET /api/expenses: sort order + optional
  # year/month filter. Just a query, so it returns the relation directly
  # rather than wrapping it in a ServiceResult -- there's no failure case here.
  class Finder
    # Only these columns can be sorted on. `order_by` is user input, so it's
    # checked against this list before touching `order()`.
    SORTABLE_COLUMNS = %w[date created_at].freeze

    def initialize(params)
      @params = params
    end

    def call
      expenses = Expense.includes(:category).order(order_column => :desc)

      if @params[:year].present? && @params[:month].present?
        expenses = expenses.where(date: date_range)
      end

      expenses
    end

    private

    def order_column
      SORTABLE_COLUMNS.include?(@params[:order_by]) ? @params[:order_by] : "date"
    end

    def date_range
      start_date = Date.new(@params[:year].to_i, @params[:month].to_i, 1)
      start_date..start_date.end_of_month
    end
  end
end
