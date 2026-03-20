# lex-swarm

**Level 3 Documentation**
- **Parent**: `/Users/miverso2/rubymine/legion/extensions-agentic/CLAUDE.md`
- **Grandparent**: `/Users/miverso2/rubymine/legion/CLAUDE.md`

## Purpose

Swarm orchestration and charter system for the LegionIO cognitive architecture. Manages the full lifecycle of multi-agent swarms: charter creation, agent role-based joining/leaving, status tracking, and completion with success/failure outcomes.

## Gem Info

- **Gem name**: `lex-swarm`
- **Version**: `0.1.2`
- **Module**: `Legion::Extensions::Swarm`
- **Ruby**: `>= 3.4`
- **License**: MIT

## File Structure

```
lib/legion/extensions/swarm/
  version.rb
  helpers/
    charter.rb      # ROLES, STATUSES, SWARM_STALE_TIMEOUT, new_charter factory, valid_role?, valid_status?
    swarm_store.rb  # SwarmStore class - create, get, join, leave, complete, active_charters
  runners/
    swarm.rb        # create_swarm, join_swarm, leave_swarm, complete_swarm, get_swarm,
                    # active_swarms, swarm_status, timeout_stale_swarms
  actors/
    stale_check.rb  # StaleCheck - Every 3600s, calls timeout_stale_swarms
spec/
  legion/extensions/swarm/
    runners/
      swarm_spec.rb
    actors/
      stale_check_spec.rb
    client_spec.rb
```

## Key Constants (Helpers::Charter)

```ruby
ROLES               = %i[finder fixer validator reviewer coordinator]
STATUSES            = %i[forming active completing disbanded failed]
SWARM_STALE_TIMEOUT = 86_400  # 24 hours
```

`new_charter` accepts `roles: []` — if empty, defaults to all five roles.

## SwarmStore Class

`Helpers::SwarmStore` stores charters in a Hash keyed by charter_id.

`join(charter_id, agent_id:, role:)` returns a symbol:
- `:not_found`, `:full`, `:already_joined`, `:joined`

The status transitions automatically: `:forming` -> `:active` when the first agent joins.

`complete(charter_id, outcome:)`:
- `:success` -> status `:completing`
- anything else -> status `:failed`
- Appends `completed_at` timestamp

`active_charters` filters by `status == :active` only (not `:forming` or `:completing`).

## Actors

| Actor | Interval | Runner Method | What It Does |
|-------|----------|---------------|--------------|
| `StaleCheck` | Every 3600s | `timeout_stale_swarms` | Iterates all charters; disbands any `:forming` or `:active` swarm older than `SWARM_STALE_TIMEOUT` (86400s) by setting status to `:disbanded` |

## Runner Symbol-to-Hash Mapping

The runner translates `SwarmStore` symbol results to response hashes using a Hash lookup pattern:
```ruby
{
  joined:         { joined: true, charter_id: charter_id },
  full:           { error: :swarm_full },
  not_found:      { error: :not_found },
  already_joined: { error: :already_joined }
}[result]
```

## Integration Points

- **lex-mesh**: swarm agents communicate via mesh multicast using capability-based routing
- **lex-swarm-github**: GitHub-specific swarm pipeline extends this base swarm with issue tracking
- **lex-governance**: large swarms or high-impact swarm objectives may require governance approval

## Development Notes

- The `timeout:` field is stored on the charter but is distinct from `SWARM_STALE_TIMEOUT` — the per-charter timeout field is not enforced; `SWARM_STALE_TIMEOUT` is enforced by the `StaleCheck` actor
- `:disbanded` status is now set by `timeout_stale_swarms` when a swarm exceeds `SWARM_STALE_TIMEOUT`
- `active_charters` only returns `:active` status; `:forming` swarms (no members yet) are not included
- `timeout_stale_swarms` checks `created_at` age (not `updated_at`) — long-lived but active swarms will still be disbanded if they exceed 24 hours
