class AddOfferToCourse < ActiveRecord::Migration[7.0]
  def change
    add_column :courses, :offer, :boolean, default: true
  end
end
