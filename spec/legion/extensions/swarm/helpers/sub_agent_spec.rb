# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Legion::Extensions::Swarm::Helpers::SubAgent do
  let(:helper_instance) { Class.new { include Legion::Extensions::Swarm::Helpers::SubAgent }.new }

  before do
    stub_const('Legion::Settings', Module.new do
      def self.dig(*keys)
        case keys
        when %i[swarm max_depth] then 3
        when %i[swarm max_concurrent] then 20
        when %i[swarm max_per_parent] then 10
        end
      end
    end)
  end

  describe '#max_depth' do
    it 'returns configured max depth' do
      expect(helper_instance.send(:max_depth)).to eq(3)
    end
  end

  describe '#max_concurrent' do
    it 'returns configured max concurrent' do
      expect(helper_instance.send(:max_concurrent)).to eq(20)
    end
  end

  describe '#max_per_parent' do
    it 'returns configured max per parent' do
      expect(helper_instance.send(:max_per_parent)).to eq(10)
    end
  end

  describe '#spawn' do
    context 'when legion-data is not available' do
      it 'returns failure' do
        result = helper_instance.spawn(runner: 'SomeRunner', function: 'do_thing',
                                       payload: {}, parent_task_id: 1)
        expect(result[:success]).to be false
        expect(result[:reason]).to eq(:data_unavailable)
      end
    end

    context 'when depth would be exceeded' do
      let(:parent_task) { double('Task', depth: 3, id: 1) }

      before do
        pt = parent_task
        task_model = Class.new do
          define_method(:[]) { |_id| pt }
        end.new
        stub_const('Legion::Data::Model::Task', task_model)
      end

      it 'returns depth_exceeded' do
        result = helper_instance.spawn(runner: 'SomeRunner', function: 'do_thing',
                                       payload: {}, parent_task_id: 1)
        expect(result[:success]).to be false
        expect(result[:reason]).to eq(:depth_exceeded)
      end
    end
  end
end
