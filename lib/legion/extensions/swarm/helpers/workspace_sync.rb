# frozen_string_literal: true

require 'time'
require_relative 'workspace'

module Legion
  module Extensions
    module Swarm
      module Helpers
        class WorkspaceSync
          include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers) &&
                                                      Legion::Extensions::Helpers.const_defined?(:Lex)

          ROUTING_PREFIX = 'swarm.workspace'

          def publish_change(charter_id:, key:, operation:, value: nil, author: nil, version: nil, **) # rubocop:disable Metrics/ParameterLists
            return { success: true, skipped: :no_transport } unless defined?(Legion::Transport)

            routing_key = "#{ROUTING_PREFIX}.#{charter_id}"
            payload     = { charter_id: charter_id, key: key, value: value,
                            author: author, version: version, operation: operation,
                            timestamp: Time.now.utc.to_s }

            Legion::Transport.publish(routing_key: routing_key, payload: payload)
            log.debug "[swarm-workspace-sync] published #{operation} #{key} to #{routing_key}"
            { success: true, routing_key: routing_key }
          rescue StandardError => e
            log.warn "[swarm-workspace-sync] publish failed: #{e.message}"
            { success: true, skipped: :publish_error, message: e.message }
          end

          def apply_incoming(charter_id:, key:, operation:, value: nil, author: nil, version: nil, timestamp: nil, **) # rubocop:disable Metrics/ParameterLists
            op = operation.to_s
            case op
            when 'put'
              ts      = timestamp.is_a?(String) ? Time.parse(timestamp) : (timestamp || Time.now.utc)
              applied = workspace.apply_remote(charter_id, key: key, value: value,
                                               author: author, version: version || 1, timestamp: ts)
              { success: true, applied: applied }
            when 'delete'
              workspace.delete(charter_id, key: key)
              { success: true, applied: true }
            else
              { success: false, reason: :unknown_operation, operation: op }
            end
          end

          private

          def workspace
            @workspace ||= Helpers::Workspace.new
          end
        end
      end
    end
  end
end
