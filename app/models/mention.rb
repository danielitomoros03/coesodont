class Mention < ApplicationRecord
  belongs_to :study_plan
  has_and_belongs_to_many :subjects


  rails_admin do
    visible false
    edit do
      fields :name, :total_required_subjects
      field :subjects do
        inline_add false
        inline_edit false
      end
    end
  end
end
