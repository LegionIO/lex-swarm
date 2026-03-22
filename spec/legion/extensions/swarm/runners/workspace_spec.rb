# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Legion::Extensions::Swarm::Runners::Workspace do
  subject(:runner) { Object.new.extend(described_class) }

  let(:charter_id) { 'charter-123' }

  before { runner.instance_variable_set(:@workspace, nil) }

  describe '#workspace_put' do
    it 'stores a value and returns success' do
      result = runner.workspace_put(charter_id: charter_id, key: 'notes', value: 'hello', author: 'agent-a')
      expect(result[:success]).to be true
      expect(result[:key]).to eq('notes')
      expect(result[:version]).to eq(1)
    end
  end

  describe '#workspace_get' do
    it 'retrieves a stored value' do
      runner.workspace_put(charter_id: charter_id, key: 'data', value: [1, 2], author: 'a')
      result = runner.workspace_get(charter_id: charter_id, key: 'data')
      expect(result[:success]).to be true
      expect(result[:entry][:value]).to eq([1, 2])
    end

    it 'returns not_found for missing key' do
      result = runner.workspace_get(charter_id: charter_id, key: 'nope')
      expect(result[:success]).to be false
      expect(result[:reason]).to eq(:not_found)
    end
  end

  describe '#workspace_list' do
    it 'lists all entries for a charter' do
      runner.workspace_put(charter_id: charter_id, key: 'a', value: 1, author: 'x')
      runner.workspace_put(charter_id: charter_id, key: 'b', value: 2, author: 'x')
      result = runner.workspace_list(charter_id: charter_id)
      expect(result[:success]).to be true
      expect(result[:count]).to eq(2)
    end
  end

  describe '#workspace_delete' do
    it 'deletes an entry and returns success' do
      runner.workspace_put(charter_id: charter_id, key: 'temp', value: 'x', author: 'a')
      result = runner.workspace_delete(charter_id: charter_id, key: 'temp')
      expect(result[:success]).to be true
    end

    it 'returns not_found for missing key' do
      result = runner.workspace_delete(charter_id: charter_id, key: 'nope')
      expect(result[:success]).to be false
      expect(result[:reason]).to eq(:not_found)
    end
  end

  describe '#workspace_clear' do
    it 'clears all entries for a charter' do
      runner.workspace_put(charter_id: charter_id, key: 'a', value: 1, author: 'x')
      result = runner.workspace_clear(charter_id: charter_id)
      expect(result[:success]).to be true
      expect(runner.workspace_list(charter_id: charter_id)[:count]).to eq(0)
    end
  end

  describe '#workspace_stats' do
    it 'returns workspace statistics' do
      runner.workspace_put(charter_id: 'c1', key: 'a', value: 1, author: 'x')
      runner.workspace_put(charter_id: 'c2', key: 'b', value: 2, author: 'y')
      result = runner.workspace_stats
      expect(result[:success]).to be true
      expect(result[:charter_count]).to eq(2)
      expect(result[:total_entries]).to eq(2)
    end
  end
end
