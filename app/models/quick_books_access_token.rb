class QuickBooksAccessToken < ApplicationRecord
  def refresh
    at = OAuth2::AccessToken.new(QB_OAUTH2_CONSUMER, access_token, refresh_token: refresh_token)
    refresh = at.refresh!

    update(
      access_token: refresh.token,
      refresh_token: refresh.refresh_token,
      token_expires_at: Time.at(refresh.expires_at)
    )
  end

  # call retrieve_customers['QueryResponse']['Customer']
  def retrieve_customers
    at = OAuth2::AccessToken.new(QB_OAUTH2_CONSUMER, access_token)
    query = CGI.escape("Select * From Customer")
    JSON.parse(at.get([
      "https://sandbox-quickbooks.api.intuit.com/v3/company/",
      "#{company_id}/query?",
      "query=#{query}"
    ].join, headers: { 'Accept' => 'application/json' }).response.body)
  end
end
