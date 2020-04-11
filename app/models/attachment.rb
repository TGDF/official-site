# frozen_string_literal: true

class Attachment < ApplicationRecord
  belongs_to :record, polymorphic: true, optional: true

  mount_uploader :file, AttachmentUploader
end
