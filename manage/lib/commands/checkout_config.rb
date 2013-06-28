require_relative 'checkout_command'

module Commands
  class CheckoutConfig < CheckoutCommand
    def name
      'checkout-config'
    end

    def project_names
      ['config']
    end
  end
end
