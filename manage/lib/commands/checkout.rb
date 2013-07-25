require_relative 'checkout_command'

module Commands
  class Checkout < CheckoutCommand
    def name
      'checkout'
    end

    def project_names
      ['main', 'worker', 'documentset-worker', 'message-broker', 'search-index']
    end
  end
end
