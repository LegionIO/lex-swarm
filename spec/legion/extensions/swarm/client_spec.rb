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

  it 'responds to workspace runner methods' do
    client = described_class.new
    expect(client).to respond_to(:workspace_put)
    expect(client).to respond_to(:workspace_get)
    expect(client).to respond_to(:workspace_list)
    expect(client).to respond_to(:workspace_delete)
    expect(client).to respond_to(:workspace_clear)
    expect(client).to respond_to(:workspace_stats)
  end

  describe '#workspace_put and #workspace_get' do
    it 'stores and retrieves workspace entries via client' do
      client = described_class.new
      client.workspace_put(charter_id: 'c1', key: 'data', value: 'hello', author: 'a')
      result = client.workspace_get(charter_id: 'c1', key: 'data')
      expect(result[:success]).to be true
      expect(result[:entry][:value]).to eq('hello')
    end
  end
end
