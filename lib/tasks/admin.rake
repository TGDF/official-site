# frozen_string_literal: true

namespace :admin do
  desc "Create a new admin user"
  task create: :environment do
    print "Email: "
    email = $stdin.gets.chomp
    print "Password: "
    password = $stdin.getpass

    begin
      AdminUser.create!(email:, password:)
      puts "Create #{email} success!"
    rescue ActiveRecord::RecordInvalid => e
      puts ""
      puts "Create admin failed!"
      puts "Reasons:"
      e.record.errors.messages.each do |field, messages|
        puts "\t#{field.to_s.capitalize}"
        messages.each { |message| puts "\t\t* #{message}" }
      end
    end
  end
end
