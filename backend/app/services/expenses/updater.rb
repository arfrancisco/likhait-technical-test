module Expenses
  class Updater
    def initialize(expense, params)
      @expense = expense
      @params = params
    end

    def call
      if @expense.update(@params)
        ServiceResult.new(true, @expense, nil)
      else
        ServiceResult.new(false, nil, @expense.errors.full_messages)
      end
    end
  end
end
