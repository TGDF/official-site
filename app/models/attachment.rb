# frozen_string_literal: true

class Attachment < ApplicationRecord
  include HasMigratedUpload

  acts_as_tenant :site, optional: true, has_global_records: true

  belongs_to :record, polymorphic: true, optional: true

  mount_uploader :file, AttachmentUploader
  has_migrated_upload :file
end
