defmodule Yolo.MatchesFileProducer do
  use GenStage

  alias Broadway.Message
  alias Broadway.NoopAcknowledger

  @enforce_keys [:matches]
  defstruct [
    :matches,
    empty: false
  ]

  @impl true
  def init(file_path) do
    updates =
      File.read!(file_path)
      |> Jason.decode!()
      |> Enum.group_by(fn %{"match_id" => match_id} -> match_id end)

    pid = self()

    Enum.each(updates, fn {match_id, match_updates} ->
      spawn_link(fn -> emit_delayed_updates(pid, match_id, match_updates) end)
    end)

    {:producer,
     %__MODULE__{
       matches: Map.keys(updates) |> MapSet.new()
     }}
  end

  @impl true
  def handle_demand(_demand, %__MODULE__{empty: true} = state) do
    {:stop, :empty, state}
  end

  def handle_demand(_demand, %__MODULE__{} = state) do
    {:noreply, [], state}
  end

  @impl true
  def handle_info({:update, update}, %__MODULE__{} = state) do
    {:noreply, [%Message{data: update, acknowledger: NoopAcknowledger.init()}], state}
  end

  def handle_info({:done, match_id}, %__MODULE__{matches: matches} = state) do
    matches = MapSet.delete(matches, match_id)
    {:noreply, [], %__MODULE__{state | matches: matches, empty: MapSet.size(matches) == 0}}
  end

  defp emit_delayed_updates(pid, match_id, match_updates) do
    Enum.each(match_updates, fn update ->
      delay = Map.get(update, "delay", 0)
      Process.sleep(delay)
      send(pid, {:update, update})
    end)

    send(pid, {:done, match_id})
  end
end
