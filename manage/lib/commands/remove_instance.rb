require_relative '../command'
require_relative '../arguments/instance'

module Commands
  class RemoveInstance < Command
    def name
      'remove-instance'
    end

    def arguments_schema
      [ Arguments::Instance.new ]
    end

    def description
      "Removes the specified instance from the registry. Does not perform any operations on the instance."
    end

    def run(runner, instance)
      state = runner.state
      state.instances.remove(instance)
      state.save
      puts "Removed #{instance.ip_address} from #{instance.env}/#{instance.type}"
    end
  end
end
