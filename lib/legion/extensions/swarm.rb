# frozen_string_literal: true

require 'legion/extensions/swarm/version'
require 'legion/extensions/swarm/helpers/charter'
require 'legion/extensions/swarm/helpers/swarm_store'
require 'legion/extensions/swarm/helpers/sub_agent'
require 'legion/extensions/swarm/helpers/workspace'
require 'legion/extensions/swarm/runners/swarm'
require 'legion/extensions/swarm/runners/spawn_child'
require 'legion/extensions/swarm/runners/workspace'

module Legion
  module Extensions
    module Swarm
      extend Legion::Extensions::Core if Legion::Extensions.const_defined? :Core, false
    end
  end
end
