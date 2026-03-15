# lex-swarm

Swarm orchestration and charter system for brain-modeled agentic AI. Manages the lifecycle of multi-agent swarms with role-based membership, objective-driven charters, and structured completion.

## Overview

`lex-swarm` enables groups of agents to coordinate on a shared objective. A swarm is created with a charter that defines its objective, the roles required, agent capacity, and a timeout. Agents join with specific roles, work toward the objective, and the swarm completes with a success or failure outcome.

## Agent Roles

| Role | Purpose |
|------|---------|
| `finder` | Identifies problems or opportunities |
| `fixer` | Implements solutions |
| `validator` | Verifies correctness of fixes |
| `reviewer` | Reviews work for quality |
| `coordinator` | Orchestrates the other roles |

## Swarm Statuses

`forming` -> `active` -> `completing` | `failed`

## Installation

Add to your Gemfile:

```ruby
gem 'lex-swarm'
```

## Usage

### Creating a Swarm

```ruby
require 'legion/extensions/swarm'

result = Legion::Extensions::Swarm::Runners::Swarm.create_swarm(
  name: "auth-bug-hunt",
  objective: "Find and fix authentication timeout bugs",
  roles: [:finder, :fixer, :validator],
  max_agents: 6,
  timeout: 7200
)
# => { charter_id: "uuid", name: "auth-bug-hunt", status: :forming }
```

### Joining a Swarm

```ruby
Legion::Extensions::Swarm::Runners::Swarm.join_swarm(
  charter_id: "uuid",
  agent_id: "agent-42",
  role: :finder
)
# => { joined: true, charter_id: "uuid" }
# When full: { error: :swarm_full }
# When already joined: { error: :already_joined }
```

### Leaving and Completing

```ruby
Legion::Extensions::Swarm::Runners::Swarm.leave_swarm(
  charter_id: "uuid",
  agent_id: "agent-42"
)

Legion::Extensions::Swarm::Runners::Swarm.complete_swarm(
  charter_id: "uuid",
  outcome: :success
)
# => { completed: true, outcome: :success }
```

### Querying

```ruby
# All active swarms
Legion::Extensions::Swarm::Runners::Swarm.active_swarms
# => { charters: [...], count: 2 }

# Specific swarm
Legion::Extensions::Swarm::Runners::Swarm.get_swarm(charter_id: "uuid")

# Overall count
Legion::Extensions::Swarm::Runners::Swarm.swarm_status
# => { total: 5 }
```

## Actors

| Actor | Interval | What It Does |
|-------|----------|--------------|
| `StaleCheck` | Every 3600s | Disbands `:forming` or `:active` swarms that have exceeded `SWARM_STALE_TIMEOUT` (86400s), enforcing the stale timeout |

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## License

MIT
