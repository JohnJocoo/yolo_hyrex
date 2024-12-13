defmodule Yolo.MatchesStorage do
  use GenServer, restart: :permanent

  alias Phoenix.PubSub

  @type match :: %{
          id: integer(),
          name: String.t(),
          status: String.t()
        }

  @table_name :matches_table

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @spec update(id :: integer(), name :: String.t(), status :: String.t()) :: :ok
  def update(id, name, status) do
    GenServer.cast(__MODULE__, {:update, id, name, status})
  end

  @spec get(id :: integer()) :: match() | nil
  def get(id) do
    case :ets.lookup(@table_name, id) do
      [] -> nil
      [{^id, _name, _status} = data] -> to_object(data)
    end
  end

  @spec all() :: list(match())
  def all() do
    :ets.tab2list(@table_name)
    |> Enum.map(&to_object/1)
  end

  @doc """
  Subscribe caller process to matches updates.
  """
  @spec subscribe() :: :ok | {:error, term()}
  def subscribe() do
    PubSub.subscribe(Yolo.PubSub, "matches")
  end

  @doc """
  Unsubscribe caller process from matches updates.
  """
  @spec unsubscribe() :: :ok | {:error, term()}
  def unsubscribe() do
    PubSub.unsubscribe(Yolo.PubSub, "matches")
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

  @impl true
  def handle_call(:clear_all, _from, state) do
    :ets.delete_all_objects(@table_name)
    {:reply, :ok, state}
  end

  defp to_object({id, name, status}), do: %{id: id, name: name, status: status}

  def _clear() do
    GenServer.call(__MODULE__, :clear_all)
  end
end
