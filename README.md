# Yolo ⚽ Matches

## Running

To start server:

  * Run `git submodule init` to checkout file with updates and football clubs icons
  * Run `mix setup` to install and setup dependencies
  * Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

```
git submodule init
mix setup
mix phx.server
```

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

## Testing

```
mix test
```

## Notes

Made with:
  * `Broadway` for reading events (updates) from file and processing them
  * `ETS` for in-memory storing (ex. usefull when user just opens page and you want to show current statuses for all matches)
  * `LiveView` for displaying all matches with (soft) real-time updates 
  * `Phoenix.PubSub` for keeping `LiveView` up to date with new matches statuses
  * `ExUnit` with `LiveView` and `Broadway` testing utilities and `GitHub` actions to run tests on push
