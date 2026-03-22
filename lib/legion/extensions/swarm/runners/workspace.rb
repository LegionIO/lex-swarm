# frozen_string_literal: true

require_relative '../helpers/workspace'

module Legion
  module Extensions
    module Swarm
      module Runners
        module Workspace
          include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers) &&
                                                      Legion::Extensions::Helpers.const_defined?(:Lex)

          def workspace_put(charter_id:, key:, value:, author:, **)
            entry = workspace.put(charter_id, key: key, value: value, author: author)
            Legion::Logging.debug "[swarm-workspace] put: charter=#{charter_id[0..7]} key=#{key} v=#{entry[:version]}"
            { success: true, key: key, version: entry[:version], charter_id: charter_id }
          end

          def workspace_get(charter_id:, key:, **)
            entry = workspace.get(charter_id, key: key)
            if entry
              { success: true, entry: entry }
            else
              { success: false, reason: :not_found, key: key, charter_id: charter_id }
            end
          end

          def workspace_list(charter_id:, **)
            entries = workspace.list(charter_id)
            { success: true, entries: entries, count: entries.size }
          end

          def workspace_delete(charter_id:, key:, **)
            removed = workspace.delete(charter_id, key: key)
            if removed
              Legion::Logging.debug "[swarm-workspace] delete: charter=#{charter_id[0..7]} key=#{key}"
              { success: true, key: key, charter_id: charter_id }
            else
              { success: false, reason: :not_found, key: key, charter_id: charter_id }
            end
          end

          def workspace_clear(charter_id:, **)
            workspace.clear_charter(charter_id)
            Legion::Logging.debug "[swarm-workspace] clear: charter=#{charter_id[0..7]}"
            { success: true, charter_id: charter_id }
          end

          def workspace_stats(**)
            workspace.stats.merge(success: true)
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
