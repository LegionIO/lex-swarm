# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Legion::Extensions::Swarm::Helpers::Workspace do
  subject(:workspace) { described_class.new }

  let(:charter_id) { 'charter-abc' }

  describe '#put and #get' do
    it 'stores and retrieves an entry' do
      workspace.put(charter_id, key: 'findings', value: { data: [1, 2, 3] }, author: 'agent-a')
      entry = workspace.get(charter_id, key: 'findings')
      expect(entry[:value]).to eq({ data: [1, 2, 3] })
      expect(entry[:author]).to eq('agent-a')
      expect(entry[:version]).to eq(1)
    end

    it 'increments version on overwrite' do
      workspace.put(charter_id, key: 'result', value: 'v1', author: 'agent-a')
      workspace.put(charter_id, key: 'result', value: 'v2', author: 'agent-b')
      entry = workspace.get(charter_id, key: 'result')
      expect(entry[:value]).to eq('v2')
      expect(entry[:author]).to eq('agent-b')
      expect(entry[:version]).to eq(2)
    end

    it 'returns nil for missing key' do
      expect(workspace.get(charter_id, key: 'nope')).to be_nil
    end

    it 'returns nil for missing charter' do
      expect(workspace.get('nonexistent', key: 'x')).to be_nil
    end
  end

  describe '#list' do
    it 'returns all entries for a charter' do
      workspace.put(charter_id, key: 'a', value: 1, author: 'x')
      workspace.put(charter_id, key: 'b', value: 2, author: 'y')
      entries = workspace.list(charter_id)
      expect(entries.keys).to contain_exactly('a', 'b')
    end

    it 'returns empty hash for unknown charter' do
      expect(workspace.list('unknown')).to eq({})
    end
  end

  describe '#delete' do
    it 'removes an entry and returns it' do
      workspace.put(charter_id, key: 'temp', value: 'data', author: 'a')
      removed = workspace.delete(charter_id, key: 'temp')
      expect(removed[:value]).to eq('data')
      expect(workspace.get(charter_id, key: 'temp')).to be_nil
    end

    it 'returns nil when key does not exist' do
      expect(workspace.delete(charter_id, key: 'nope')).to be_nil
    end
  end

  describe '#clear_charter' do
    it 'removes all entries for a charter' do
      workspace.put(charter_id, key: 'a', value: 1, author: 'x')
      workspace.put(charter_id, key: 'b', value: 2, author: 'x')
      workspace.clear_charter(charter_id)
      expect(workspace.list(charter_id)).to eq({})
    end
  end

  describe '#apply_remote' do
    it 'applies a remote put when version is higher' do
      workspace.put(charter_id, key: 'shared', value: 'local', author: 'a')
      workspace.apply_remote(charter_id, key: 'shared', value: 'remote', author: 'b',
                             version: 5, timestamp: Time.now.utc)
      expect(workspace.get(charter_id, key: 'shared')[:value]).to eq('remote')
      expect(workspace.get(charter_id, key: 'shared')[:version]).to eq(5)
    end

    it 'ignores remote put when version is lower' do
      workspace.put(charter_id, key: 'shared', value: 'local', author: 'a')
      workspace.put(charter_id, key: 'shared', value: 'local2', author: 'a')
      workspace.apply_remote(charter_id, key: 'shared', value: 'stale', author: 'b',
                             version: 1, timestamp: Time.now.utc)
      expect(workspace.get(charter_id, key: 'shared')[:value]).to eq('local2')
    end

    it 'uses timestamp to break version ties' do
      workspace.put(charter_id, key: 'tie', value: 'old', author: 'a')
      later = Time.now.utc + 1
      workspace.apply_remote(charter_id, key: 'tie', value: 'newer', author: 'b',
                             version: 1, timestamp: later)
      expect(workspace.get(charter_id, key: 'tie')[:value]).to eq('newer')
    end
  end

  describe '#stats' do
    it 'returns charter count and total entries' do
      workspace.put('c1', key: 'a', value: 1, author: 'x')
      workspace.put('c1', key: 'b', value: 2, author: 'x')
      workspace.put('c2', key: 'c', value: 3, author: 'y')
      stats = workspace.stats
      expect(stats[:charter_count]).to eq(2)
      expect(stats[:total_entries]).to eq(3)
    end
  end
end
