OAUTH_CONSUMER_KEY = "Q0Qi2A03fQqevqBimQqr0YJcHn7DW5mvRtzKq450QiJ43KGFvh"
OAUTH_CONSUMER_SECRET = "0NoizqLckN4lbEiUyW4LJH2LhoW34EGr53mKtlsa"

oauth_params = {
  :site => "https://appcenter.intuit.com/connect/oauth2",
  :authorize_url => "https://appcenter.intuit.com/connect/oauth2",
  :token_url => "https://oauth.platform.intuit.com/oauth2/v1/tokens/bearer"
}

::QB_OAUTH2_CONSUMER = OAuth2::Client.new(OAUTH_CONSUMER_KEY, OAUTH_CONSUMER_SECRET, oauth_params)
Quickbooks.sandbox_mode = true
