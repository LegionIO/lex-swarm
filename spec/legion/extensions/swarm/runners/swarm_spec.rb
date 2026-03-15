# frozen_string_literal: true

require 'legion/extensions/swarm/client'

RSpec.describe Legion::Extensions::Swarm::Runners::Swarm do
  let(:client) { Legion::Extensions::Swarm::Client.new }

  describe '#create_swarm' do
    it 'creates a swarm charter' do
      result = client.create_swarm(name: 'test-swarm', objective: 'fix bugs')
      expect(result[:charter_id]).to match(/\A[0-9a-f-]{36}\z/)
      expect(result[:status]).to eq(:forming)
    end
  end

  describe '#join_swarm' do
    it 'adds agent to swarm' do
      swarm = client.create_swarm(name: 'test', objective: 'test')
      result = client.join_swarm(charter_id: swarm[:charter_id], agent_id: 'a1', role: :finder)
      expect(result[:joined]).to be true
    end

    it 'rejects invalid role' do
      swarm = client.create_swarm(name: 'test', objective: 'test')
      result = client.join_swarm(charter_id: swarm[:charter_id], agent_id: 'a1', role: :invalid)
      expect(result[:error]).to eq(:invalid_role)
    end

    it 'prevents duplicate joins' do
      swarm = client.create_swarm(name: 'test', objective: 'test')
      client.join_swarm(charter_id: swarm[:charter_id], agent_id: 'a1', role: :finder)
      result = client.join_swarm(charter_id: swarm[:charter_id], agent_id: 'a1', role: :fixer)
      expect(result[:error]).to eq(:already_joined)
    end
  end

  describe '#complete_swarm' do
    it 'completes a swarm' do
      swarm = client.create_swarm(name: 'test', objective: 'test')
      result = client.complete_swarm(charter_id: swarm[:charter_id], outcome: :success)
      expect(result[:completed]).to be true
    end
  end

  describe '#active_swarms' do
    it 'lists active swarms' do
      swarm = client.create_swarm(name: 'test', objective: 'test')
      client.join_swarm(charter_id: swarm[:charter_id], agent_id: 'a1', role: :finder)
      result = client.active_swarms
      expect(result[:count]).to eq(1)
    end
  end

  describe '#timeout_stale_swarms' do
    it 'returns zero disbanded when store is empty' do
      result = client.timeout_stale_swarms
      expect(result[:disbanded]).to eq(0)
      expect(result[:disbanded_ids]).to eq([])
    end

    it 'does not disband a freshly created swarm' do
      client.create_swarm(name: 'fresh', objective: 'test')
      result = client.timeout_stale_swarms
      expect(result[:disbanded]).to eq(0)
    end

    it 'disbands a stale forming swarm' do
      swarm = client.create_swarm(name: 'stale', objective: 'test')
      # backdate created_at past the timeout threshold
      store = client.send(:swarm_store)
      store.charters[swarm[:charter_id]][:created_at] = Time.now.utc - 90_000
      result = client.timeout_stale_swarms
      expect(result[:disbanded]).to eq(1)
      expect(result[:disbanded_ids]).to include(swarm[:charter_id])
    end

    it 'reports correct checked count' do
      client.create_swarm(name: 's1', objective: 'test')
      client.create_swarm(name: 's2', objective: 'test')
      result = client.timeout_stale_swarms
      expect(result[:checked]).to eq(2)
    end
  end
end
