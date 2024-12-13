defmodule Yolo.MatchesPipeTest do
  use ExUnit.Case, async: false

  alias Yolo.MatchesStorage

  setup _tags do
    on_exit(fn ->
      MatchesStorage._clear()
    end)

    :ok
  end

  test "put event" do
    MatchesStorage.subscribe()

    ref = Broadway.test_message(Yolo.MatchesPipe, %{
      "name" => "Real Madrid vs Barcelona",
      "status" => "active",
      "crash" => false,
      "delay" => 0,
      "match_id" => 4
    })

    assert_receive {:ack, ^ref, [%{data: %{
      "name" => "Real Madrid vs Barcelona",
      "status" => "active",
      "crash" => false,
      "delay" => 0,
      "match_id" => 4
    }}], []}

    assert_receive {:match_update, %{id: 4, name: "Real Madrid vs Barcelona", status: "active"}}
    MatchesStorage.unsubscribe()
  end
end
