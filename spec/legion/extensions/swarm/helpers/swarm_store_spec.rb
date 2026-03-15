# frozen_string_literal: true

RSpec.describe Legion::Extensions::Swarm::Helpers::SwarmStore do
  let(:store) { described_class.new }
  let(:charter_helper) { Legion::Extensions::Swarm::Helpers::Charter }

  let(:charter) { charter_helper.new_charter(name: 'test-swarm', objective: 'fix bugs') }

  describe '#initialize' do
    it 'starts with an empty charters hash' do
      expect(store.charters).to eq({})
    end
  end

  describe '#create' do
    it 'stores the charter by its charter_id' do
      id = store.create(charter)
      expect(store.charters[id]).to eq(charter)
    end

    it 'returns the charter_id' do
      id = store.create(charter)
      expect(id).to eq(charter[:charter_id])
    end

    it 'stores multiple charters independently' do
      c1 = charter_helper.new_charter(name: 'swarm-a', objective: 'a')
      c2 = charter_helper.new_charter(name: 'swarm-b', objective: 'b')
      store.create(c1)
      store.create(c2)
      expect(store.count).to eq(2)
    end
  end

  describe '#get' do
    it 'returns the charter for a known id' do
      store.create(charter)
      expect(store.get(charter[:charter_id])).to eq(charter)
    end

    it 'returns nil for an unknown id' do
      expect(store.get('nonexistent-id')).to be_nil
    end
  end

  describe '#join' do
    before { store.create(charter) }

    it 'returns :joined when agent successfully joins' do
      result = store.join(charter[:charter_id], agent_id: 'agent-1', role: :finder)
      expect(result).to eq(:joined)
    end

    it 'adds the agent to the charter agents list' do
      store.join(charter[:charter_id], agent_id: 'agent-1', role: :finder)
      agents = store.get(charter[:charter_id])[:agents]
      expect(agents.size).to eq(1)
      expect(agents.first[:agent_id]).to eq('agent-1')
    end

    it 'stores the role on the joined agent record' do
      store.join(charter[:charter_id], agent_id: 'agent-1', role: :finder)
      expect(store.get(charter[:charter_id])[:agents].first[:role]).to eq(:finder)
    end

    it 'records joined_at as a UTC Time' do
      before = Time.now.utc
      store.join(charter[:charter_id], agent_id: 'agent-1', role: :finder)
      after = Time.now.utc
      ts = store.get(charter[:charter_id])[:agents].first[:joined_at]
      expect(ts).to be_between(before, after)
    end

    it 'transitions status from :forming to :active on first join' do
      store.join(charter[:charter_id], agent_id: 'agent-1', role: :finder)
      expect(store.get(charter[:charter_id])[:status]).to eq(:active)
    end

    it 'keeps status :active when a second agent joins' do
      store.join(charter[:charter_id], agent_id: 'agent-1', role: :finder)
      store.join(charter[:charter_id], agent_id: 'agent-2', role: :fixer)
      expect(store.get(charter[:charter_id])[:status]).to eq(:active)
    end

    it 'returns :not_found for unknown charter_id' do
      result = store.join('unknown-id', agent_id: 'agent-1', role: :finder)
      expect(result).to eq(:not_found)
    end

    it 'returns :already_joined when the agent is already a member' do
      store.join(charter[:charter_id], agent_id: 'agent-1', role: :finder)
      result = store.join(charter[:charter_id], agent_id: 'agent-1', role: :fixer)
      expect(result).to eq(:already_joined)
    end

    it 'returns :full when max_agents is reached' do
      small_charter = charter_helper.new_charter(name: 'tiny', objective: 'min', max_agents: 1)
      store.create(small_charter)
      store.join(small_charter[:charter_id], agent_id: 'a1', role: :finder)
      result = store.join(small_charter[:charter_id], agent_id: 'a2', role: :fixer)
      expect(result).to eq(:full)
    end

    it 'does not modify the charter when returning :full' do
      small_charter = charter_helper.new_charter(name: 'tiny', objective: 'min', max_agents: 1)
      store.create(small_charter)
      store.join(small_charter[:charter_id], agent_id: 'a1', role: :finder)
      store.join(small_charter[:charter_id], agent_id: 'a2', role: :fixer)
      expect(store.get(small_charter[:charter_id])[:agents].size).to eq(1)
    end
  end

  describe '#leave' do
    before do
      store.create(charter)
      store.join(charter[:charter_id], agent_id: 'agent-1', role: :finder)
    end

    it 'returns :left when agent successfully leaves' do
      result = store.leave(charter[:charter_id], agent_id: 'agent-1')
      expect(result).to eq(:left)
    end

    it 'removes the agent from the agents list' do
      store.leave(charter[:charter_id], agent_id: 'agent-1')
      expect(store.get(charter[:charter_id])[:agents]).to be_empty
    end

    it 'returns :not_member for an agent not in the charter' do
      result = store.leave(charter[:charter_id], agent_id: 'agent-99')
      expect(result).to eq(:not_member)
    end

    it 'returns :not_found for unknown charter_id' do
      result = store.leave('unknown-id', agent_id: 'agent-1')
      expect(result).to eq(:not_found)
    end

    it 'leaves other members unaffected' do
      store.join(charter[:charter_id], agent_id: 'agent-2', role: :fixer)
      store.leave(charter[:charter_id], agent_id: 'agent-1')
      agents = store.get(charter[:charter_id])[:agents]
      expect(agents.map { |a| a[:agent_id] }).to contain_exactly('agent-2')
    end
  end

  describe '#complete' do
    before { store.create(charter) }

    it 'sets status to :completing on success outcome' do
      store.complete(charter[:charter_id], outcome: :success)
      expect(store.get(charter[:charter_id])[:status]).to eq(:completing)
    end

    it 'sets status to :failed on non-success outcome' do
      store.complete(charter[:charter_id], outcome: :failure)
      expect(store.get(charter[:charter_id])[:status]).to eq(:failed)
    end

    it 'sets status to :failed for an arbitrary non-success outcome' do
      store.complete(charter[:charter_id], outcome: :timeout)
      expect(store.get(charter[:charter_id])[:status]).to eq(:failed)
    end

    it 'records completed_at as a UTC Time' do
      before = Time.now.utc
      store.complete(charter[:charter_id], outcome: :success)
      after = Time.now.utc
      ts = store.get(charter[:charter_id])[:completed_at]
      expect(ts).to be_between(before, after)
    end

    it 'stores the outcome on the charter' do
      store.complete(charter[:charter_id], outcome: :success)
      expect(store.get(charter[:charter_id])[:outcome]).to eq(:success)
    end

    it 'returns the updated charter hash' do
      result = store.complete(charter[:charter_id], outcome: :success)
      expect(result[:charter_id]).to eq(charter[:charter_id])
    end

    it 'returns nil for unknown charter_id' do
      expect(store.complete('unknown-id', outcome: :success)).to be_nil
    end
  end

  describe '#active_charters' do
    it 'returns an empty array when no charters exist' do
      expect(store.active_charters).to eq([])
    end

    it 'excludes charters with :forming status' do
      store.create(charter)
      expect(store.active_charters).to eq([])
    end

    it 'returns charters with :active status' do
      store.create(charter)
      store.join(charter[:charter_id], agent_id: 'a1', role: :finder)
      expect(store.active_charters.size).to eq(1)
    end

    it 'excludes charters with :completing status' do
      store.create(charter)
      store.join(charter[:charter_id], agent_id: 'a1', role: :finder)
      store.complete(charter[:charter_id], outcome: :success)
      expect(store.active_charters).to eq([])
    end

    it 'excludes charters with :failed status' do
      store.create(charter)
      store.join(charter[:charter_id], agent_id: 'a1', role: :finder)
      store.complete(charter[:charter_id], outcome: :error)
      expect(store.active_charters).to eq([])
    end

    it 'returns only the active subset among multiple charters' do
      c1 = charter_helper.new_charter(name: 'active', objective: 'a')
      c2 = charter_helper.new_charter(name: 'forming', objective: 'b')
      store.create(c1)
      store.create(c2)
      store.join(c1[:charter_id], agent_id: 'a1', role: :finder)
      expect(store.active_charters.size).to eq(1)
      expect(store.active_charters.first[:charter_id]).to eq(c1[:charter_id])
    end
  end

  describe '#count' do
    it 'returns 0 for an empty store' do
      expect(store.count).to eq(0)
    end

    it 'returns the number of charters stored' do
      store.create(charter)
      expect(store.count).to eq(1)
    end

    it 'counts all charters regardless of status' do
      c1 = charter_helper.new_charter(name: 'a', objective: 'a')
      c2 = charter_helper.new_charter(name: 'b', objective: 'b')
      store.create(c1)
      store.create(c2)
      store.join(c1[:charter_id], agent_id: 'a1', role: :finder)
      store.complete(c1[:charter_id], outcome: :success)
      expect(store.count).to eq(2)
    end
  end
end
