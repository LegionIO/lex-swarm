# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../../../lib/legion/extensions/swarm/actors/workspace_sync'

RSpec.describe Legion::Extensions::Swarm::Actors::WorkspaceSync do
  subject(:actor) { described_class.allocate }

  describe '#publish_change' do
    it 'returns skipped when transport is not available' do
      result = actor.publish_change(charter_id: 'c1', key: 'k', value: 'v',
                                    author: 'a', version: 1, operation: :put)
      expect(result[:success]).to be true
      expect(result[:skipped]).to eq(:no_transport)
    end
  end

  describe '#apply_incoming' do
    let(:workspace) { Legion::Extensions::Swarm::Helpers::Workspace.new }

    before { actor.instance_variable_set(:@workspace, workspace) }

    it 'applies a remote put operation' do
      result = actor.apply_incoming(
        charter_id: 'c1', key: 'shared', value: 'remote-data',
        author: 'remote-agent', version: 1, timestamp: Time.now.utc.to_s, operation: 'put'
      )
      expect(result[:success]).to be true
      expect(result[:applied]).to be true
      expect(workspace.get('c1', key: 'shared')[:value]).to eq('remote-data')
    end

    it 'applies a remote delete operation' do
      workspace.put('c1', key: 'doomed', value: 'bye', author: 'local')
      result = actor.apply_incoming(
        charter_id: 'c1', key: 'doomed', operation: 'delete'
      )
      expect(result[:success]).to be true
      expect(workspace.get('c1', key: 'doomed')).to be_nil
    end

    it 'rejects unknown operations' do
      result = actor.apply_incoming(charter_id: 'c1', key: 'x', operation: 'explode')
      expect(result[:success]).to be false
      expect(result[:reason]).to eq(:unknown_operation)
    end
  end
end
