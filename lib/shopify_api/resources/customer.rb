module ShopifyAPI
  class Customer < Base
    include Metafields

    def orders
      Order.find(:all, params: {customer_id: self.id})
    end

    def self.search(params)
      find(:all, from: :search, params: params)
    end

    def invite
      load_attributes_from_response(post(:invite))
    end

  end
end
