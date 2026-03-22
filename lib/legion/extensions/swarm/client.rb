# frozen_string_literal: true

require 'legion/extensions/swarm/helpers/charter'
require 'legion/extensions/swarm/helpers/swarm_store'
require 'legion/extensions/swarm/runners/swarm'
require 'legion/extensions/swarm/runners/workspace'

module Legion
  module Extensions
    module Swarm
      class Client
        include Runners::Swarm
        include Runners::Workspace

        def initialize(**)
          @swarm_store = Helpers::SwarmStore.new
        end

        private

        attr_reader :swarm_store
      end
    end
  end
end
