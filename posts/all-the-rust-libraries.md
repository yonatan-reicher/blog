Want to serialize an object? Do fancy terminal stuff? What rust libraries do you
need for your specific use case?

This is a list of libraries that I use for rust.

Goals for this list:
1. Be minimal. Only include 1 library for each 1 thing.
2. Grow. I want to keep adding things to this list :).


- `functionality` - Rust functional programming basics.
- `nessie-parse` - Parsing (mostly for langs).
- `crossterm` - Fancy terminal stuff. Colors/cursor/keyboard. Not for a TUI,
  it's more raw than that.
- `serde` - A classic. Serialize/Deserialize everything. Use the `derive`
  feature flag. `toml` for human readable. `rmp-serde` for compact.
- `noise` - More advanced random numbers. Includes Perlin noise and friends.
- `dirs` - Get standard directories to save all your application data n stuff.
