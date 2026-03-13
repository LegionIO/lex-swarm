# frozen_string_literal: true

module Legion
  module Extensions
    module Swarm
      module Runners
        module Swarm
          include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers) &&
                                                      Legion::Extensions::Helpers.const_defined?(:Lex)

          def create_swarm(name:, objective:, roles: [], max_agents: 10, timeout: 3600, **) # rubocop:disable Metrics/ParameterLists
            charter = Helpers::Charter.new_charter(name: name, objective: objective,
                                                   roles: roles, max_agents: max_agents, timeout: timeout)
            id = swarm_store.create(charter)
            { charter_id: id, name: name, status: :forming }
          end

          def join_swarm(charter_id:, agent_id:, role:, **)
            return { error: :invalid_role, valid: Helpers::Charter::ROLES } unless Helpers::Charter.valid_role?(role)

            result = swarm_store.join(charter_id, agent_id: agent_id, role: role)
            {
              joined:         { joined: true, charter_id: charter_id },
              full:           { error: :swarm_full },
              not_found:      { error: :not_found },
              already_joined: { error: :already_joined }
            }[result]
          end

          def leave_swarm(charter_id:, agent_id:, **)
            result = swarm_store.leave(charter_id, agent_id: agent_id)
            {
              left:       { left: true },
              not_found:  { error: :not_found },
              not_member: { error: :not_member }
            }[result]
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
