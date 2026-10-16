# Development data. Idempotent: it can be run several times without duplicating records.

puts "Creating seeds..."

[
  { email: "romer@example.com", name: "Romer", last_name: "Ramos", initials: "RR", username: "romerramos" },
  { email: "fran@gmail.com", name: "Fran", last_name: "Barahona", initials: "FB", username: "fran" },
  { email: "chris@gmail.com", name: "Christian", last_name: "Benjumea", initials: "CB", username: "chris" }
].each do |attributes|
  User.find_or_create_by!(email: attributes[:email]) do |user|
    user.assign_attributes(attributes.merge(password: "12345678", password_confirmation: "12345678"))
  end
end

project = Project.find_or_create_by!(name: "Postgram") do |p|
  p.assign_attributes(description: "Take it slow...", start_date: Date.new(2024, 6, 1), velocity: 10, volatility: 10, sprint_length: 2)
end
project.recreate_sprints if project.sprints.empty?

9.times { |i| project.items.find_or_create_by!(name: "test #{i}") { |item| item.kind = :bug } }

puts "Seeds created!"
