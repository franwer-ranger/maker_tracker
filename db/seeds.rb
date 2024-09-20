# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

puts "Creating seeds..."
User.create(email: "romerramos@gmail.com", password: "12345678", password_confirmation: "12345678", name: "Romer", last_name: "Ramos", pseudonym: "RR")
project = Project.create(name: "Postgram", description: "Take it slow...", start_date: Date.new(2024, 06, 01), velocity: 10, volatility: 10, sprint_length: 2)
project.recreate_sprints

9.times { |i| Item.create!(name: "test #{i}", project_id: 1, kind: :bug) }
puts "Seeds created!"
