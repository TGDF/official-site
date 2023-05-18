# frozen_string_literal: true

Given('there are some plans') do |table|
  table.hashes.each do |plan|
    Plan.create!(**plan)
  end
end
