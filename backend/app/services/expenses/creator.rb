module Expenses
  class Creator
    def initialize(params)
      @params = params
    end

    def call
      expense = Expense.new(@params)

      if expense.save
        ServiceResult.new(true, expense, nil)
      else
        ServiceResult.new(false, nil, expense.errors.full_messages)
      end
    end
  end
end
