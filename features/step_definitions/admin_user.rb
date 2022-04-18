# frozen_string_literal: true

Given('an user logged as admin') do
  user = create(:admin_user, password: 'Passw0rd$')
  visit '/admin/sign_in'
  fill_in 'admin_user_email', with: user.email
  fill_in 'admin_user_password', with: 'Passw0rd$'
  click_on '登入'
end
