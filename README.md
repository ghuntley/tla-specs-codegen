# TLA+ Go Concurrency Bug Analysis

This repository contains implementations based on Hillel Wayne's blog post about using TLA+ to find concurrency bugs in Go programs.

## Files

- `deadlock.go` - Go implementation that demonstrates the deadlock bug
- `channels.tla` - TLA+ specification modeling the original buggy Go code
- `channels.cfg` - Configuration file for the TLA+ model checker
- `channels_fix1.tla` - Fix 1: Goroutines acquire tokens themselves
- `channels_fix2.tla` - Fix 2: Release tokens before sending to found channel
- `channels_fix3.tla` - Fix 3: Run the spawning loop in a separate goroutine

## Running the Examples

### Go Code
The Go code will deadlock when run:
```bash
go run deadlock.go
# Output: fatal error: all goroutines are asleep - deadlock!
```

### TLA+ Specifications
To run the TLA+ model checker on any of the specifications, you need TLA+ tools installed.

1. Run the original buggy specification:
```bash
tlc channels_simple.tla -config channels_simple.cfg
# Result: Deadlock found after 19 states
```

2. Run the fixes:
```bash
tlc channels_fix1.tla -config channels_fix1.cfg
# Result: Still has temporal property violations

tlc channels_fix2.tla -config channels_fix2.cfg  
# Result: ✅ SUCCESS - All properties satisfied

tlc channels_fix3.tla -config channels_fix3.cfg
# Result: Still deadlocks
```

## The Bug

The deadlock occurs because:
1. Main process fills the `limitCh` buffer and spawns goroutines
2. Each goroutine tries to send to the unbuffered `found` channel
3. Main process is blocked in the for loop, not yet reading from `found`
4. All goroutines are blocked waiting to send, holding their tokens
5. Deadlock: main can't read `found`, goroutines can't send to `found`

## The Fixes

1. **Fix 1**: Goroutines acquire tokens themselves instead of main doing it upfront
2. **Fix 2**: Goroutines release tokens before attempting to send to `found`
3. **Fix 3**: Move the spawning loop to a separate goroutine so main can immediately start reading

All fixes prevent the scenario where goroutines hold tokens while blocked on sending.
