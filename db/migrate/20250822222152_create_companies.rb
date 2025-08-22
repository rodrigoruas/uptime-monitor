class CreateCompanies < ActiveRecord::Migration[8.0]
  def change
    create_table :companies do |t|
      t.string :name
      t.string :stripe_customer_id
      t.string :subscription_status
      t.string :plan_type

      t.timestamps
    end
  end
end
