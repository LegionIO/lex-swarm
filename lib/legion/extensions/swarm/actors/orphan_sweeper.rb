# frozen_string_literal: true

module Legion
  module Extensions
    module Swarm
      module Actor
        class OrphanSweeper < Legion::Extensions::Actors::Every
          def time = 300
          def run_now? = false
          def use_runner? = false
          def runner_class = self.class
          def check_subtask? = false
          def generate_task? = false

          def action(**_opts)
            return { swept: 0 } unless defined?(Legion::Data)

            tasks = Legion::Data.connection[:tasks]
            orphans = tasks.exclude(parent_id: nil)
                           .exclude(status: %w[complete failed])
                           .all
                           .select do |t|
              parent = tasks.where(id: t[:parent_id]).first
              parent.nil? || %w[complete failed].include?(parent[:status])
            end

            orphans.each do |orphan|
              tasks.where(id: orphan[:id]).update(status: 'failed')
            end

            { swept: orphans.size }
          rescue StandardError => e
            { swept: 0, error: e.message }
          end
        end
      end
    end
  end
end
