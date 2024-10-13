class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable


  has_many :items
  has_many :comments
  
  def full_name
    return email if name.nil? || last_name.nil?
    "#{name} #{last_name}"
  end

  def nickname
    return pseudonym if pseudonym.present?
    "#{name.first.capitalize}#{last_name.first.capitalize}"
  end
end
