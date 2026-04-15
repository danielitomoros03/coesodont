class AddBitacoraIndexToVersions < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    add_index :versions,
              [:item_type, :item_id, :created_at],
              name: 'index_versions_on_item_type_item_id_created_at',
              algorithm: :concurrently,
              if_not_exists: true
  end
end
