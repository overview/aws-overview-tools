require_relative 'checkout_command'

module Commands
  class Checkout < CheckoutCommand
    def name
      'checkout'
    end

    def repository_name
      'main'
    end
  end
end
