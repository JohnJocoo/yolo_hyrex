defmodule YoloWeb.Utils do
  import ExUnit.Assertions

  alias Yolo.MatchesStorage

  def update_match(id, name, status) do
    MatchesStorage.subscribe()
    MatchesStorage.update(id, name, status)
    assert_receive {:match_update, %{id: ^id, name: ^name, status: ^status}}
    MatchesStorage.unsubscribe()
  end

  def wait_until(0, fun), do: fun.()

  def wait_until(timeout, fun) do
    try do
      fun.()
    rescue
      ExUnit.AssertionError ->
        :timer.sleep(10)
        wait_until(max(0, timeout - 10), fun)
    end
  end

end
