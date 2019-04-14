class HomeController < ApplicationController
  def index
  end

  def grant
    redirect_uri = 'http://localhost:3000/home/quick_book_oauth_callback'

    grant_url = ::QB_OAUTH2_CONSUMER.auth_code.authorize_url(
      redirect_uri: redirect_uri,
      response_type: "code",
      state: SecureRandom.hex(12),
      scope: "com.intuit.quickbooks.accounting" # change scope to suit your need
    )
    redirect_to grant_url
  end

  def quick_books_oauth_callback
    redirect_uri = 'http://localhost:3000/home/quick_book_oauth_callback'
    if resp = ::QB_OAUTH2_CONSUMER.auth_code.get_token(
        params[:code], :redirect_uri => redirect_uri)

      QuickBooksAccessToken.destroy_all

      # save quickbook access token for next time use
      QuickBooksAccessToken.create(
        access_token: resp.token,
        refresh_token: resp.refresh_token,
        company_id: params[:realmId],
        token_expires_at: Time.at(resp.expires_at)
      )
    end

    render json: { result: :ok }
  end
end
