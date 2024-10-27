module UsersHelper
  def users_options(users)
    users.map { |user| [ "#{user.full_name} (#{user.initials_safe})", user.id ] }
  end
end
