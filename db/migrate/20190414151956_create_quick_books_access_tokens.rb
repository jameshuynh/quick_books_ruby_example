class CreateQuickBooksAccessTokens < ActiveRecord::Migration[5.2]
  def change
    create_table :quick_books_access_tokens do |t|
      t.text :access_token
      t.text :refresh_token
      t.string :company_id
      t.datetime :token_expires_at

      t.timestamps
    end
  end
end
