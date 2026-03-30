# frozen_string_literal: true

require 'legion/extensions/actors/every'

module Legion
  module Extensions
    module Swarm
      module Actor
        class StaleCheck < Legion::Extensions::Actors::Every # rubocop:disable Legion/Extension/EveryActorRequiresTime
          def runner_class
            Legion::Extensions::Swarm::Runners::Swarm
          end

          def runner_function
            'timeout_stale_swarms'
          end

          def time
            3600
          end

          def run_now?
            false
          end

          def use_runner?
            false
          end

          def check_subtask?
            false
          end

          def generate_task?
            false
          end
        end
      end
    end
  end
end
