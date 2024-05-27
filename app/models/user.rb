class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable


  def full_name
    return email if name.nil? || last_name.nil?
    "#{name} #{last_name}"
  end

  def nickname
    "#{name.first.capitalize}#{last_name.first.capitalize}"
  end
end
