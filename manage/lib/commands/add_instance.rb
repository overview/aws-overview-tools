require_relative '../command'
require_relative '../arguments/instance'

module Commands
  class AddInstance < Command
    def name
      'add-instance'
    end

    def arguments_schema
      [ Arguments::Instance.new ]
    end

    def description
      "Adds the specified instance to the registry. Does not perform any operations on the instance."
    end

    def run(runner, instance)
      state = runner.state
      state.instances << instance
      state.save
      puts "Added #{instance.ip_address} to #{instance.env}/#{instance.type}"
    end
  end
end
