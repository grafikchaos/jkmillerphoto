class Photo < ActiveRecord::Base

  # =============
  # image file uploads
  # =============
  mount_uploader :image, ImageUploader

  # =============
  # ActiveModel Observers:
  # =============
  before_validation :populate_name_if_blank
  before_save :track_published_at  if :published_changed?

  # =============
  # Validations
  # =============
  validates :name, presence: true

  protected

    def populate_name_if_blank
      self.name = file_name unless self.name.present?
    end

    def track_published_at
      if published?
        self.published_at = Time.zone.now
      else
        self.published_at = nil
      end
    end

end
