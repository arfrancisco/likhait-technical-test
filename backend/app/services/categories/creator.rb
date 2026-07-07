module Categories
  class Creator
    def initialize(params)
      @params = params
    end

    def call
      category = Category.new(@params)

      if category.save
        ServiceResult.new(true, category, nil)
      else
        ServiceResult.new(false, nil, category.errors.full_messages)
      end
    end
  end
end
