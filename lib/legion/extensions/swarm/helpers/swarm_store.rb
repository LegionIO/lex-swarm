# frozen_string_literal: true

module Legion
  module Extensions
    module Swarm
      module Helpers
        class SwarmStore
          attr_reader :charters

          def initialize
            @charters = {}
          end

          def create(charter)
            @charters[charter[:charter_id]] = charter
            charter[:charter_id]
          end

          def get(charter_id)
            @charters[charter_id]
          end

          def join(charter_id, agent_id:, role:)
            charter = @charters[charter_id]
            return :not_found unless charter
            return :full if charter[:agents].size >= charter[:max_agents]
            return :already_joined if charter[:agents].any? { |a| a[:agent_id] == agent_id }

            charter[:agents] << { agent_id: agent_id, role: role, joined_at: Time.now.utc }
            charter[:status] = :active if charter[:status] == :forming
            :joined
          end

          def leave(charter_id, agent_id:)
            charter = @charters[charter_id]
            return :not_found unless charter

            removed = charter[:agents].reject! { |a| a[:agent_id] == agent_id }
            removed ? :left : :not_member
          end

          def complete(charter_id, outcome:)
            charter = @charters[charter_id]
            return nil unless charter

            charter[:status] = outcome == :success ? :completing : :failed
            charter[:completed_at] = Time.now.utc
            charter[:outcome] = outcome
            charter
          end

          def active_charters
            @charters.values.select { |c| c[:status] == :active }
          end

          def count
            @charters.size
          end
        end
      end
    end
  end
end
