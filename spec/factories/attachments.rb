# frozen_string_literal: true

FactoryBot.define do
  factory :attachment do
    record_type { 'MyString' }
    record_id { '' }
    file { 'MyString' }
  end
end
