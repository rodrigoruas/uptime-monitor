class CreateSiteMonitors < ActiveRecord::Migration[8.0]
  def change
    create_table :site_monitors do |t|
      t.string :name
      t.string :url
      t.references :company, null: false, foreign_key: true
      t.string :status
      t.datetime :last_checked_at
      t.integer :check_interval

      t.timestamps
    end
  end
end
