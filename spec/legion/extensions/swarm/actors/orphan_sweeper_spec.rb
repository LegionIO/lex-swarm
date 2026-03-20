# frozen_string_literal: true

module Legion
  module Extensions
    module Actors
      unless defined?(Every)
        class Every # rubocop:disable Lint/EmptyClass
        end
      end
    end
  end
end

$LOADED_FEATURES << 'legion/extensions/actors/every'

require_relative '../../../../../lib/legion/extensions/swarm/actors/orphan_sweeper'

RSpec.describe Legion::Extensions::Swarm::Actor::OrphanSweeper do
  subject(:actor) { described_class.new }

  describe '#time' do
    it 'returns 300 seconds' do
      expect(actor.time).to eq(300)
    end
  end

  describe '#run_now?' do
    it 'returns false' do
      expect(actor.run_now?).to be false
    end
  end

  describe '#action' do
    context 'when Legion::Data is not available' do
      it 'returns zero swept' do
        result = actor.action
        expect(result[:swept]).to eq(0)
      end
    end
  end
end
