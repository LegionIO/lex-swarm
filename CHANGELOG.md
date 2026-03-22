# Changelog

## [0.2.0] - 2026-03-22

### Added
- `Helpers::Workspace`: per-charter in-memory shared scratch space with Mutex-based thread safety
- `Runners::Workspace`: runner methods (workspace_put, workspace_get, workspace_list, workspace_delete, workspace_clear, workspace_stats)
- `Actors::WorkspaceSync`: AMQP broadcast sync for cross-node workspace convergence (last-writer-wins with version + timestamp)
- `apply_remote` for conflict resolution on incoming workspace updates
- Client now includes Workspace runner

## [0.1.2] - 2026-03-20

### Added
- `Helpers::SubAgent` module with `spawn` method for depth-tracked recursive sub-agent creation
- `Runners::SpawnChild` module delegating to SubAgent for task spawning via AMQP

## [0.1.1] - 2026-03-14

### Added
- `StaleCheck` actor (Every 3600s) — calls `timeout_stale_swarms` to disband swarms exceeding `SWARM_STALE_TIMEOUT` (86400s), enforcing the previously defined-but-not-enforced timeout

## [0.1.0] - 2026-03-13

### Added
- Initial release
