# frozen_string_literal: true

require 'legion/extensions/swarm/client'

RSpec.describe Legion::Extensions::Swarm::Client do
  it 'responds to swarm runner methods' do
    client = described_class.new
    expect(client).to respond_to(:create_swarm)
    expect(client).to respond_to(:join_swarm)
    expect(client).to respond_to(:leave_swarm)
    expect(client).to respond_to(:complete_swarm)
    expect(client).to respond_to(:get_swarm)
    expect(client).to respond_to(:active_swarms)
    expect(client).to respond_to(:swarm_status)
  end
end
