# frozen_string_literal: true

RSpec.describe Legion::Extensions::Swarm::Helpers::Charter do
  describe 'constants' do
    it 'defines ROLES as the five swarm roles' do
      expect(described_class::ROLES).to eq(%i[finder fixer validator reviewer coordinator])
    end

    it 'defines STATUSES as the five lifecycle statuses' do
      expect(described_class::STATUSES).to eq(%i[forming active completing disbanded failed])
    end
  end

  describe '.new_charter' do
    let(:charter) { described_class.new_charter(name: 'test-swarm', objective: 'fix all bugs') }

    it 'returns a hash with a UUID charter_id' do
      expect(charter[:charter_id]).to match(/\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/)
    end

    it 'stores the provided name' do
      expect(charter[:name]).to eq('test-swarm')
    end

    it 'stores the provided objective' do
      expect(charter[:objective]).to eq('fix all bugs')
    end

    it 'defaults status to :forming' do
      expect(charter[:status]).to eq(:forming)
    end

    it 'starts with an empty agents array' do
      expect(charter[:agents]).to eq([])
    end

    it 'sets completed_at to nil' do
      expect(charter[:completed_at]).to be_nil
    end

    it 'records created_at as a UTC Time' do
      before = Time.now.utc
      c = described_class.new_charter(name: 'n', objective: 'o')
      after = Time.now.utc
      expect(c[:created_at]).to be_between(before, after)
    end

    it 'defaults to all ROLES when roles is empty' do
      expect(charter[:roles]).to eq(described_class::ROLES)
    end

    it 'uses the provided roles array when non-empty' do
      c = described_class.new_charter(name: 'n', objective: 'o', roles: %i[finder fixer])
      expect(c[:roles]).to eq(%i[finder fixer])
    end

    it 'defaults max_agents to 10' do
      expect(charter[:max_agents]).to eq(10)
    end

    it 'accepts a custom max_agents value' do
      c = described_class.new_charter(name: 'n', objective: 'o', max_agents: 5)
      expect(c[:max_agents]).to eq(5)
    end

    it 'defaults timeout to 3600' do
      expect(charter[:timeout]).to eq(3600)
    end

    it 'accepts a custom timeout value' do
      c = described_class.new_charter(name: 'n', objective: 'o', timeout: 7200)
      expect(c[:timeout]).to eq(7200)
    end

    it 'generates unique charter_ids for each call' do
      c1 = described_class.new_charter(name: 'a', objective: 'b')
      c2 = described_class.new_charter(name: 'a', objective: 'b')
      expect(c1[:charter_id]).not_to eq(c2[:charter_id])
    end
  end

  describe '.valid_role?' do
    it 'returns true for all defined ROLES' do
      described_class::ROLES.each do |role|
        expect(described_class.valid_role?(role)).to be true
      end
    end

    it 'returns true for :finder' do
      expect(described_class.valid_role?(:finder)).to be true
    end

    it 'returns true for :coordinator' do
      expect(described_class.valid_role?(:coordinator)).to be true
    end

    it 'returns false for an unknown role' do
      expect(described_class.valid_role?(:operator)).to be false
    end

    it 'returns false for nil' do
      expect(described_class.valid_role?(nil)).to be false
    end

    it 'returns false for a string version of a valid role' do
      expect(described_class.valid_role?('finder')).to be false
    end
  end

  describe '.valid_status?' do
    it 'returns true for all defined STATUSES' do
      described_class::STATUSES.each do |status|
        expect(described_class.valid_status?(status)).to be true
      end
    end

    it 'returns true for :forming' do
      expect(described_class.valid_status?(:forming)).to be true
    end

    it 'returns true for :disbanded' do
      expect(described_class.valid_status?(:disbanded)).to be true
    end

    it 'returns false for an unknown status' do
      expect(described_class.valid_status?(:pending)).to be false
    end

    it 'returns false for nil' do
      expect(described_class.valid_status?(nil)).to be false
    end

    it 'returns false for a string version of a valid status' do
      expect(described_class.valid_status?('active')).to be false
    end
  end
end
