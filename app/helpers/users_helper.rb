module UsersHelper
  def users_options(users)
    users.map { |user| [ user.full_name, user.id ] }
  end
end
