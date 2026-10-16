# Tokens de agente (historia #014): cuándo se usó cada token por última vez, y
# un índice único para encontrar al actor por el digest de su token.
class AddTokenUsedAtToActors < ActiveRecord::Migration[8.1]
  def change
    add_column :actors, :token_used_at, :datetime
    add_index :actors, :token_digest, unique: true
  end
end
