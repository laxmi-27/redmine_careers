class Career < ApplicationRecord
  belongs_to :project
  has_many :issues, dependent: :destroy
  has_one_attached :resume

  validates :location, presence: true
  validates :experience, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :qualification, presence: true
  validates :position, presence: true
  validates :name, presence: true

  # Resume validations for file type and size
  validate :correct_resume_mime_type
  validate :resume_size

  private

  def correct_resume_mime_type
    if resume.attached? && !resume.content_type.in?(%w(application/pdf application/msword application/vnd.openxmlformats-officedocument.wordprocessingml.document))
      errors.add(:resume, 'must be a PDF or Word document')
    end
  end

  def resume_size
    if resume.attached? && resume.byte_size > 5.megabytes
      errors.add(:resume, 'should be less than 5 MB')
    end
  end
end
