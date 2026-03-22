# frozen_string_literal: true

module Legion
  module Extensions
    module Swarm
      module Helpers
        class Workspace
          def initialize
            @store = {}
            @mutex = Mutex.new
          end

          def put(charter_id, key:, value:, author:)
            @mutex.synchronize do
              charter_store = (@store[charter_id] ||= {})
              existing = charter_store[key]
              version = existing ? existing[:version] + 1 : 1
              charter_store[key] = {
                key:       key,
                value:     value,
                author:    author,
                version:   version,
                timestamp: Time.now.utc
              }
            end
          end

          def get(charter_id, key:)
            @mutex.synchronize do
              @store.dig(charter_id, key)
            end
          end

          def list(charter_id)
            @mutex.synchronize do
              (@store[charter_id] || {}).dup
            end
          end

          def delete(charter_id, key:)
            @mutex.synchronize do
              charter_store = @store[charter_id]
              return nil unless charter_store

              charter_store.delete(key)
            end
          end

          def clear_charter(charter_id)
            @mutex.synchronize do
              @store.delete(charter_id)
            end
          end

          def apply_remote(charter_id, **entry)
            key       = entry[:key]
            value     = entry[:value]
            author    = entry[:author]
            version   = entry[:version]
            timestamp = entry[:timestamp]

            @mutex.synchronize do
              charter_store = (@store[charter_id] ||= {})
              existing = charter_store[key]

              if existing.nil? || version > existing[:version] ||
                 (version == existing[:version] && timestamp > existing[:timestamp])
                charter_store[key] = {
                  key:       key,
                  value:     value,
                  author:    author,
                  version:   version,
                  timestamp: timestamp
                }
                return true
              end
              false
            end
          end

          def stats
            @mutex.synchronize do
              total = @store.values.sum(&:size)
              { charter_count: @store.size, total_entries: total }
            end
          end
        end
      end
    end
  end
end
