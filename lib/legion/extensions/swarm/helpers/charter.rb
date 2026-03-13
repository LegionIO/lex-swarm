# frozen_string_literal: true

require 'securerandom'

module Legion
  module Extensions
    module Swarm
      module Helpers
        module Charter
          ROLES = %i[finder fixer validator reviewer coordinator].freeze
          STATUSES = %i[forming active completing disbanded failed].freeze

          module_function

          def new_charter(name:, objective:, roles: [], max_agents: 10, timeout: 3600)
            {
              charter_id:  SecureRandom.uuid,
              name:        name,
              objective:   objective,
              roles:       roles.empty? ? ROLES : roles,
              max_agents:  max_agents,
              timeout:     timeout,
              status:      :forming,
              agents:      [],
              created_at:  Time.now.utc,
              completed_at: nil
            }
          end

          def valid_role?(role)
            ROLES.include?(role)
          end

          def valid_status?(status)
            STATUSES.include?(status)
          end
        end
      end
    end
  end
end
