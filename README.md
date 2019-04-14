This is an example app on how to retrieve and refresh access token in quick book:

# Run this example

```
bundle install
rails server
```

- Visit http://localhost:3000/home/index
- Click on Quick Books button
- Click Connect on the pop up window
- Wait until you see `{ "result": "ok" }`
- Go into rails console (i.e. `rails c`)
- Run `QuickBooksAccessToken.last.retrieve_customers`

# Instructions

## 1. Add oauth2 gem

```
# Gemfile

gem 'oauth2', '~> 1.4.1'
```

## 2. Create config/initializers/quick_books.rb

```rb
# please get the consumer key & secret from the app created in quickbooks

OAUTH_CONSUMER_KEY = "Q0Qi2A03fQqevqBimQqr0YJcHn7DW5mvRtzKq450QiJ43KGFvh"
OAUTH_CONSUMER_SECRET = "0NoizqLckN4lbEiUyW4LJH2LhoW34EGr53mKtlsa"

oauth_params = {
  :site => "https://appcenter.intuit.com/connect/oauth2",
  :authorize_url => "https://appcenter.intuit.com/connect/oauth2",
  :token_url => "https://oauth.platform.intuit.com/oauth2/v1/tokens/bearer"
}

::QB_OAUTH2_CONSUMER = OAuth2::Client.new(OAUTH_CONSUMER_KEY, OAUTH_CONSUMER_SECRET, oauth_params)
Quickbooks.sandbox_mode = true
```

## 3. Create a controller called HomeController with index action

```rb
class HomeController < ApplicationController
  def index
  end
end
```

Create ``home/index.html.erb`` view with the content:

```html.erb
<!-- somewhere in your document include the Javascript -->
<script type="text/javascript"
        src="https://appcenter.intuit.com/Content/IA/intuit.ipp.anywhere.js">
</script>

<script>
intuit.ipp.anywhere.setup({grantUrl: 'http://localhost:3000/home/grant'});
</script>

<!-- this will display a button that the user clicks to start the flow -->
<ipp:connectToIntuit></ipp:connectToIntuit>
```

The URL `http://localhost:3000/home/grant` must be an absolute URL.

## 4. Create grant action inside Home controller

Create a Redirect URI inside quick book application. The redirect URI must be an absolute URL

``http://localhost:3000/home/quick_books_oauth_callback``

<img src='https://raw.githubusercontent.com/jameshuynh/quick_books_ruby_example/master/public/screenshot1.png' />

And then create action grant with the following content:

```rb
class HomeController < ApplicationController
  # ...
  def grant
    # redirect_uri callback from quick books
    redirect_uri = 'http://localhost:3000/home/quick_books_oauth_callback'

    grant_url = ::QB_OAUTH2_CONSUMER.auth_code.authorize_url(
      redirect_uri: redirect_uri,
      response_type: "code",
      state: SecureRandom.hex(12),
      scope: "com.intuit.quickbooks.accounting" # change scope to suit your need
    )
    redirect_to grant_url
  end
end
```

## 5. Create a model to store access token

```
rails g model quick_books_access_token access_token:text refresh_token:text company_id token_expires_at:datetime
```

## 6. Run migration

```bash
bundle exec rake db:migrate
```

## 7. Listen to oauth2 callback to store access token

Create action `quick_books_oauth_callback` inside `HomeController` to listen to oauth callback. The purpose is to store the very first access token. This access token can be used to refresh itself later or can be used to retrieve data later

```rb
class HomeController < ApplicationController
  # ...

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
```

## 8. Add code to refresh token

5 - Inside QuickBookAccessToken model, add `refresh!` method

```rb
class QuickBooksAccessToken < ApplicationRecord
  def refresh!
    at = OAuth2::AccessToken.new(QB_OAUTH2_CONSUMER, access_token, refresh_token: refresh_token)
    refresh = at.refresh!

    update(
      access_token: refresh.token,
      refresh_token: refresh.refresh_token,
      token_expires_at: Time.at(refresh.expires_at)
    )
  end
end
```

## 9. Retrieve data from quick_books_access_token.rb

Add this function inside ``quick_books_access_token.rb`` to retrieve data

```rb
class QuickBooksAccessToken < ApplicationRecord
  
  # ...
  
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
```

## 10. Schedule QuickBooksAccessToken.last.refresh! to run every 30 mins (using whenever & cron job)

Inside `config/scheduler.rb`

```
every 30.mins do
  runner 'QuickBooksAccessToken.last.refresh'
end

```

## 11. To retrieve customers in the future, simply call:

```rb
response = QuickBooksAccessToken.last.retrieve_customers
response[‘QueryResponse’][Customer’].each do |customer|
  # work with customer data
end
```
