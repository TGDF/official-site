# frozen_string_literal: true

require 'rails_helper'

RSpec.describe(AdminUser) do
  let(:email) { 'admin@example.com' }

  describe '#display_name' do
    it 'use email account as display name' do
      user = described_class.new(email: email)
      expect(user.display_name).to(eq(email.split('@').first))
    end
  end

  describe '#avatar' do
    it 'generate gravatar url' do
      hash = Digest::MD5.hexdigest(email)
      user = described_class.new(email: email)
      expect(user.avatar).to(include(hash))
    end
  end
end
