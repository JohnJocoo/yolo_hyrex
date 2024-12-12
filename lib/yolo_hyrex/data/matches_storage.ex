defmodule Yolo.MatchesStorage do
  use GenServer, restart: :permanent

  alias Phoenix.PubSub

  @table_name :matches_table

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def update(id, name, status) do
    GenServer.cast(__MODULE__, {:update, id, name, status})
  end

  def get(id) do
    case :ets.lookup(@table_name, id) do
      [] -> nil
      [{^id, _name, _status} = data] -> to_object(data)
    end
  end

  def all() do
    :ets.tab2list(@table_name)
    |> Enum.map(&to_object/1)
  end

  def subscribe() do
    PubSub.subscribe(Yolo.PubSub, "matches")
  end

  @impl true
  def init(_opts) do
    :ets.new(@table_name, [:set, :protected, :named_table])

    {:ok, nil}
  end

  @impl true
  def handle_cast({:update, id, name, status}, state) do
    :ets.insert(@table_name, {id, name, status})
    PubSub.broadcast(Yolo.PubSub, "matches", {:match_update, to_object({id, name, status})})
    {:noreply, state}
  end

  defp to_object({id, name, status}), do: %{id: id, name: name, status: status}
end
