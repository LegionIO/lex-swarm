# frozen_string_literal: true

module Legion
  module Extensions
    module Swarm
      module Runners
        module Swarm
          include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers) &&
                                                      Legion::Extensions::Helpers.const_defined?(:Lex)

          def create_swarm(name:, objective:, roles: [], max_agents: 10, timeout: 3600, **)
            charter = Helpers::Charter.new_charter(name: name, objective: objective,
                                                   roles: roles, max_agents: max_agents, timeout: timeout)
            id = swarm_store.create(charter)
            { charter_id: id, name: name, status: :forming }
          end

          def join_swarm(charter_id:, agent_id:, role:, **)
            unless Helpers::Charter.valid_role?(role)
              return { error: :invalid_role, valid: Helpers::Charter::ROLES }
            end

            result = swarm_store.join(charter_id, agent_id: agent_id, role: role)
            case result
            when :joined     then { joined: true, charter_id: charter_id }
            when :full       then { error: :swarm_full }
            when :not_found  then { error: :not_found }
            when :already_joined then { error: :already_joined }
            end
          end

          def leave_swarm(charter_id:, agent_id:, **)
            result = swarm_store.leave(charter_id, agent_id: agent_id)
            case result
            when :left       then { left: true }
            when :not_found  then { error: :not_found }
            when :not_member then { error: :not_member }
            end
          end

          def complete_swarm(charter_id:, outcome:, **)
            result = swarm_store.complete(charter_id, outcome: outcome)
            result ? { completed: true, outcome: outcome } : { error: :not_found }
          end

          def get_swarm(charter_id:, **)
            charter = swarm_store.get(charter_id)
            charter ? { found: true, charter: charter } : { found: false }
          end

          def active_swarms(**)
            charters = swarm_store.active_charters
            { charters: charters, count: charters.size }
          end

          def swarm_status(**)
            { total: swarm_store.count }
          end

          private

          def swarm_store
            @swarm_store ||= Helpers::SwarmStore.new
          end
        end
      end
    end
  end
end
