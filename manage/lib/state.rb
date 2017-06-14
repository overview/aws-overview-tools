require_relative 'instance_collection'

class State
  attr_reader(:instances)

  def initialize(ec2_client)
    @instances = InstanceCollection.read_from_aws(ec2_client)
  end
end
