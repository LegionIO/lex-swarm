# frozen_string_literal: true

require 'legion/extensions/swarm/version'
require 'legion/extensions/swarm/helpers/charter'
require 'legion/extensions/swarm/helpers/swarm_store'
require 'legion/extensions/swarm/runners/swarm'

module Legion
  module Extensions
    module Swarm
      extend Legion::Extensions::Core if Legion::Extensions.const_defined? :Core
    end
  end
end
