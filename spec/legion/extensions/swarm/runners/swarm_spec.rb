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
end
