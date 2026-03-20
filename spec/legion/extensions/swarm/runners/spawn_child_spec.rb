# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Legion::Extensions::Swarm::Runners::SpawnChild do
  let(:runner_instance) { Class.new { include Legion::Extensions::Swarm::Runners::SpawnChild }.new }

  before do
    stub_const('Legion::Settings', Module.new do
      def self.dig(*_keys) = nil
    end)
  end

  describe '#spawn_child' do
    it 'delegates to SubAgent.spawn and returns result' do
      result = runner_instance.spawn_child(runner: 'R', function: 'f',
                                           payload: {}, parent_task_id: 1)
      expect(result).to be_a(Hash)
      expect(result).to have_key(:success)
    end
  end
end
