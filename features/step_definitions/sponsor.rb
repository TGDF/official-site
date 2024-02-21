# frozen_string_literal: true

Given('there are some sponsor levels') do |table|
  table.hashes.each do |attr|
    SponsorLevel.create!(**attr)
  end
end

Given('there are some sponsors') do |table|
  table.hashes.each do |attr|
    attr['level'] = SponsorLevel.i18n.find_by!(name: attr.delete('level'))
    attr['logo'] = uploaded_thumbnail(attr['logo'])

    Sponsor.create!(**attr)
  end
end
