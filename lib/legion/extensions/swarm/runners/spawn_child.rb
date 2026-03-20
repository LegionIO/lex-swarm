# frozen_string_literal: true

module Legion
  module Extensions
    module Swarm
      module Runners
        module SpawnChild
          include Helpers::SubAgent if defined?(Helpers::SubAgent)

          def spawn_child(runner:, function:, payload:, parent_task_id:, **)
            spawn(runner: runner, function: function, payload: payload, parent_task_id: parent_task_id)
          end
        end
      end
    end
  end
end
