# frozen_string_literal: true

module Legion
  module Extensions
    module Swarm
      module Helpers
        module SubAgent
          def spawn(runner:, function:, payload:, parent_task_id:, **)
            return { success: false, reason: :data_unavailable } unless defined?(Legion::Data::Model::Task)

            parent = Legion::Data::Model::Task[parent_task_id]
            return { success: false, reason: :parent_not_found } unless parent

            new_depth = (parent.respond_to?(:depth) ? parent.depth.to_i : 0) + 1

            return { success: false, reason: :depth_exceeded } if new_depth > max_depth
            return { success: false, reason: :concurrent_exceeded } if concurrent_children_count > max_concurrent
            return { success: false, reason: :per_parent_exceeded } if children_of(parent_task_id) > max_per_parent

            if defined?(Legion::Ingress)
              result = Legion::Ingress.run(
                payload:       payload,
                runner_class:  runner,
                function:      function,
                source:        'sub_agent',
                generate_task: true,
                check_subtask: false
              )
              { success: true, task_id: result[:task_id], depth: new_depth }
            else
              { success: false, reason: :ingress_unavailable }
            end
          rescue StandardError => e
            { success: false, reason: :error, message: e.message }
          end

          private

          def max_depth
            Legion::Settings.dig(:swarm, :max_depth) || 3
          rescue StandardError
            3
          end

          def max_concurrent
            Legion::Settings.dig(:swarm, :max_concurrent) || 20
          rescue StandardError
            20
          end

          def max_per_parent
            Legion::Settings.dig(:swarm, :max_per_parent) || 10
          rescue StandardError
            10
          end

          def concurrent_children_count
            return 0 unless defined?(Legion::Data)

            Legion::Data.connection[:tasks]
                        .exclude(parent_id: nil)
                        .exclude(status: %w[complete failed])
                        .count
          rescue StandardError
            0
          end

          def children_of(parent_task_id)
            return 0 unless defined?(Legion::Data)

            Legion::Data.connection[:tasks]
                        .where(parent_id: parent_task_id)
                        .exclude(status: %w[complete failed])
                        .count
          rescue StandardError
            0
          end
        end
      end
    end
  end
end
