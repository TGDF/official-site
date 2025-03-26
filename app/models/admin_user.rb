# frozen_string_literal: true

class AdminUser < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable,
         :rememberable, :trackable, :validatable

  has_many :news, as: :author, dependent: :nullify, inverse_of: :author

  # TODO: Add display name field
  def display_name
    email.split("@").first
  end

  def avatar(size: 100)
    hash = Digest::MD5.hexdigest(email)
    "https://www.gravatar.com/avatar/#{hash}?s=#{size}"
  end
end
