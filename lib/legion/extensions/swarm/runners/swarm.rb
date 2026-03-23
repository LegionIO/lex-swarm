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
            log.info "[swarm] created: id=#{id[0..7]} name=#{name} max=#{max_agents} roles=#{roles.join(',')}"
            { charter_id: id, name: name, status: :forming }
          end

          def join_swarm(charter_id:, agent_id:, role:, **)
            return { error: :invalid_role, valid: Helpers::Charter::ROLES } unless Helpers::Charter.valid_role?(role)

            result = swarm_store.join(charter_id, agent_id: agent_id, role: role)
            log.debug "[swarm] join: charter=#{charter_id[0..7]} agent=#{agent_id} role=#{role} result=#{result}"
            log.info "[swarm] agent joined: charter=#{charter_id[0..7]} agent=#{agent_id} role=#{role}" if result == :joined
            {
              joined:         { joined: true, charter_id: charter_id },
              full:           { error: :swarm_full },
              not_found:      { error: :not_found },
              already_joined: { error: :already_joined }
            }[result]
          end

          def leave_swarm(charter_id:, agent_id:, **)
            result = swarm_store.leave(charter_id, agent_id: agent_id)
            log.debug "[swarm] leave: charter=#{charter_id[0..7]} agent=#{agent_id} result=#{result}"
            log.info "[swarm] agent left: charter=#{charter_id[0..7]} agent=#{agent_id}" if result == :left
            {
              left:       { left: true },
              not_found:  { error: :not_found },
              not_member: { error: :not_member }
            }[result]
          end

          def complete_swarm(charter_id:, outcome:, **)
            result = swarm_store.complete(charter_id, outcome: outcome)
            if result
              log.info "[swarm] completed: charter=#{charter_id[0..7]} outcome=#{outcome}"
            else
              log.debug "[swarm] complete failed: charter=#{charter_id[0..7]} not found"
            end
            result ? { completed: true, outcome: outcome } : { error: :not_found }
          end

          def get_swarm(charter_id:, **)
            charter = swarm_store.get(charter_id)
            log.debug "[swarm] get: charter=#{charter_id[0..7]} found=#{!charter.nil?}"
            charter ? { found: true, charter: charter } : { found: false }
          end

          def active_swarms(**)
            charters = swarm_store.active_charters
            log.debug "[swarm] active: count=#{charters.size}"
            { charters: charters, count: charters.size }
          end

          def swarm_status(**)
            total = swarm_store.count
            log.debug "[swarm] status: total=#{total}"
            { total: total }
          end

          def timeout_stale_swarms(**)
            now        = Time.now.utc
            timeout    = Helpers::Charter::SWARM_STALE_TIMEOUT
            disbanded  = []
            swarm_store.charters.each_value do |charter|
              next unless %i[forming active].include?(charter[:status])
              next unless now - charter[:created_at] > timeout

              charter[:status] = :disbanded
              disbanded << charter[:charter_id]
            end
            log.debug "[swarm] stale check: checked=#{swarm_store.charters.size} disbanded=#{disbanded.size}"
            { checked: swarm_store.charters.size, disbanded: disbanded.size, disbanded_ids: disbanded }
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
