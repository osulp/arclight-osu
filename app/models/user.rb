# frozen_string_literal: true

class User < ApplicationRecord
  # Connects this user object to Blacklights Bookmarks.
  include Blacklight::User
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :cas_authenticatable

  # Configuration added by Blacklight; Blacklight::User uses a method key on your
  # user class to get a user-displayable login/identifier for
  # the account.
  self.string_display_key ||= :email

  def cas_extra_attributes=(extra_attributes)
    extra_attributes.each do |name, value|
      case name.to_sym
      when :fullname
        self.display_name = value
      when :email
        self.email = value
      end
    end
  end
end
