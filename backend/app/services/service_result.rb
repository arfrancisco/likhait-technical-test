# Shared return value for the create/update services below, so controllers
# have one consistent shape to branch on instead of re-checking
# `record.errors` themselves. Deliberately just a plain Struct -- no base
# class or interface module, since a create/update result is only ever
# "did it work, and here's either the record or the errors."
ServiceResult = Struct.new(:success?, :data, :errors)
