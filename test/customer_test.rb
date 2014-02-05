require 'test_helper'

class CustomerTest < Test::Unit::TestCase

  def test_get
    fake "customers/207119551", :method => :get, :body => load_fixture('customer')
    customer = ShopifyAPI::Customer.find(207119551)
    assert_equal "Norman", customer.last_name
  end

  def test_search
    fake "customers/search.json?query=Bob+country%3AUnited+States", extension: false, body: load_fixture('customers_search')

    results = ShopifyAPI::Customer.search(query: 'Bob country:United States')
    assert_equal 'Bob', results.first.first_name
  end

  def test_invite
    fake "customers/207119551", :method => :get, :body => load_fixture('customer')
    customer = ShopifyAPI::Customer.find(207119551)
    fake "customers/207119551/invite", :method => :post, :body => load_fixture('customer')
    customer.invite
  end

end
