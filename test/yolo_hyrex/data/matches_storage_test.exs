defmodule Yolo.MatchesStorageTest do
  use ExUnit.Case, async: false

  import YoloWeb.Utils

  alias Yolo.MatchesStorage

  setup _tags do
    on_exit(fn ->
      MatchesStorage._clear()
    end)

    :ok
  end

  test "empty" do
    assert nil == MatchesStorage.get(100)
    assert [] == MatchesStorage.all()
  end

  test "put match" do
    MatchesStorage.update(3, "Braga vs Famalição", "active")

    wait_until(1000, fn ->
      assert %{
               id: 3,
               name: "Braga vs Famalição",
               status: "active"
             } == MatchesStorage.get(3)
    end)

    assert [
             %{
               id: 3,
               name: "Braga vs Famalição",
               status: "active"
             }
           ] == MatchesStorage.all()
  end

  test "update match" do
    update_match(3, "Braga vs Famalição", "paused")

    assert %{
             id: 3,
             name: "Braga vs Famalição",
             status: "paused"
           } == MatchesStorage.get(3)

    assert [
             %{
               id: 3,
               name: "Braga vs Famalição",
               status: "paused"
             }
           ] == MatchesStorage.all()

    MatchesStorage.update(3, "Braga vs Famalição", "active")

    wait_until(1000, fn ->
      assert %{
               id: 3,
               name: "Braga vs Famalição",
               status: "active"
             } == MatchesStorage.get(3)
    end)

    assert [
             %{
               id: 3,
               name: "Braga vs Famalição",
               status: "active"
             }
           ] == MatchesStorage.all()
  end

  test "receive update notification" do
    update_match(5, "Braga vs Famalição", "paused")

    assert %{
             id: 5,
             name: "Braga vs Famalição",
             status: "paused"
           } == MatchesStorage.get(5)

    MatchesStorage.subscribe()
    MatchesStorage.update(5, "Braga vs Famalição", "active")
    assert_receive {:match_update, %{id: 5, name: "Braga vs Famalição", status: "active"}}
    MatchesStorage.unsubscribe()
  end

  test "receive update notification when new inserted" do
    MatchesStorage.subscribe()
    MatchesStorage.update(5, "Braga vs Famalição", "active")
    assert_receive {:match_update, %{id: 5, name: "Braga vs Famalição", status: "active"}}
    MatchesStorage.unsubscribe()
  end
end
