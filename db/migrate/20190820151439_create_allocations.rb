class CreateAllocations < ActiveRecord::Migration[5.2]
  def change
    create_table :allocations, id: :uuid do |t|
      t.references :allocatable,
        type: :uuid,
        polymorphic: true,
        null: false,
        index: {
          name: 'index_allocations_on_al_type_and_al_id'
        }

      t.references :allocation_receivable,
        type: :uuid,
        polymorphic: true,
        null: false,
        index: {
          name: 'index_allocations_on_al_rec_type_and_al_rec_id'
        }

      t.timestamps

      t.index %i[
        allocatable_type
        allocatable_id
        allocation_receivable_type
        allocation_receivable_id
      ],
      name: 'index_allocations_on_al_and_al_rec_unique',
      unique: true
    end
  end
end
