class CreateMonitorChecks < ActiveRecord::Migration[8.0]
  def change
    create_table :monitor_checks do |t|
      t.references :site_monitor, null: false, foreign_key: true
      t.integer :status_code
      t.float :response_time
      t.datetime :checked_at
      t.text :error_message

      t.timestamps
    end
  end
end
