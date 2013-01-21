require_relative 'checkout_command'

module Commands
  class CheckoutConfig < CheckoutCommand
    def name
      'checkout-config'
    end

    def repository_name
      'config'
    end
  end
end
