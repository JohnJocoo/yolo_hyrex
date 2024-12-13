defmodule YoloWeb.MatchesLive do
  use YoloWeb, :live_view

  import TAI

  alias Yolo.MatchesStorage

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      MatchesStorage.subscribe()
    end

    now = :erlang.monotonic_time()

    socket = assign(socket,
      matches: MatchesStorage.all()
              |> Map.new(fn %{id: id} = data -> {id, Map.put(data, :ts, now)} end),
      sort_by: {:name, :asc},
      page_title: "⚽ Matches"
    )

    {:ok, socket}
  end

  @impl true
  def handle_params(%{"sort_by" => "latest"}, _uri, socket) do
    socket = assign(socket, sort_by: {:latest, nil})
    {:noreply, socket}
  end

  def handle_params(%{"sort_by" => sort_by_raw, "sort_order" => sort_order_raw}, _uri, socket) do
    sort_by = to_atom_in(sort_by_raw, [:name, :status])
    sort_order = to_atom_in(sort_order_raw, [:asc, :desc])
    socket = assign(socket, sort_by: {sort_by, sort_order})
    {:noreply, socket}
  end

  def handle_params(%{}, _uri, socket) do
    socket = assign(socket, sort_by: {:name, :asc})
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    {current_sort_by, current_sort_order} = assigns.sort_by

    {sorter, order} =
      case {current_sort_by, current_sort_order} do
        {:latest, _} ->
          {fn %{ts: ts} -> ts end, :desc}

        {:name, order} ->
          {fn %{name: name} -> name end, order}

        {:status, order} ->
          {
            fn %{status: status} ->
              case status do
                "active" -> 1
                "paused" -> 2
                _ -> 3
              end
            end,
            order
          }
      end

    matches =
      Map.values(assigns.matches)
      |> Enum.sort_by(sorter, order)

    assigns = assign(assigns,
      current_sort_by: current_sort_by,
      current_sort_order: current_sort_order,
      matches: matches)

    ~H"""
    <h1>Matches</h1>
    <div class="matches">
      <ul>
        <li class="header">
          <span class="logos">
            <.sort_link sort_by={:latest} current_sort_by={@current_sort_by} current_sort_order={@current_sort_order}>
              <.icon name="hero-arrow-down" />
            </.sort_link>
          </span>
          <span class="name">
          <.sort_link sort_by={:name} current_sort_by={@current_sort_by} current_sort_order={@current_sort_order}>
            Name
          </.sort_link>
          </span>
          <span class="status">
            <.sort_link sort_by={:status} current_sort_by={@current_sort_by} current_sort_order={@current_sort_order}>
              Status
            </.sort_link>
          </span>
        </li>
        <.match :for={match <- @matches} match={match} />
      </ul>
    </div>
    """
  end

  @impl true
  def handle_info({:match_update, %{id: id} = match}, socket) do
    match = Map.put(match, :ts, :erlang.monotonic_time())

    socket = assign(socket,
      matches: Map.put(socket.assigns.matches, id, match)
    )

    {:noreply, socket}
  end

  attr :match, :map, required: true
  def match(assigns) do
    ~H"""
    <li class="match">
      <.logos match_name={@match.name} />
      <span class="name">
        <%= @match.name %>
      </span>
      <span class={["status", @match.status]}>
        <%= @match.status %>
      </span>
    </li>
    """
  end

  attr :match_name, :string, required: true
  def logos(assigns) do
    {left, right} = get_logos_path(assigns.match_name)
    assigns = assign(assigns, left: left, right: right)

    ~H"""
      <div class="logos">
        <img src={@left} /> &nbsp | &nbsp <img src={@right} />
      </div>
    """
  end

  attr :sort_by, :atom, required: true
  attr :current_sort_by, :atom, required: true
  attr :current_sort_order, :atom, required: true
  slot :inner_block, required: true
  def sort_link(assigns) do
    params =
      cond do
        assigns.sort_by == :latest ->
          %{sort_by: :latest}

        assigns.sort_by == assigns.current_sort_by ->
          %{sort_by: assigns.sort_by, sort_order: opposite_sort_order(assigns.current_sort_order)}

        true ->
          %{sort_by: assigns.sort_by, sort_order: :desc}
      end

    assigns = assign(assigns, params: params)

    ~H"""
      <.link patch={
        ~p"/matches?#{@params}"
        }>
        <%= render_slot(@inner_block) %>
        <.icon :if={@sort_by != :latest and @sort_by == @current_sort_by}
          name={if @current_sort_order == :desc, do: "hero-arrow-up", else: "hero-arrow-down"} />
      </.link>
    """
  end

  defp opposite_sort_order(:asc), do: :desc
  defp opposite_sort_order(:desc), do: :asc

  defp get_logos_path("Real Madrid vs Barcelona") do
    {
      "/images/football-logos/logos/Spain - LaLiga/Real Madrid.png",
      "/images/football-logos/logos/Spain - LaLiga/FC Barcelona.png"
    }
  end

  defp get_logos_path("Liverpool vs Chelsea") do
    {
      "/images/football-logos/logos/England - Premier League/Liverpool FC.png",
      "/images/football-logos/logos/England - Premier League/Chelsea FC.png"
    }
  end

  defp get_logos_path("Manchester City vs Tottenham") do
    {
      "/images/football-logos/logos/England - Premier League/Manchester City.png",
      "/images/football-logos/logos/England - Premier League/Tottenham Hotspur.png"
    }
  end

  defp get_logos_path("Inter Milan vs AC Milan") do
    {
      "/images/football-logos/logos/Italy - Serie A/Inter Milan.png",
      "/images/football-logos/logos/Italy - Serie A/AC Milan.png"
    }
  end

  defp get_logos_path("Ajax vs PSV") do
    {
      "/images/football-logos/logos/Netherlands - Eredivisie/Ajax Amsterdam.png",
      "/images/football-logos/logos/Netherlands - Eredivisie/PSV Eindhoven.png"
    }
  end

  defp get_logos_path("Arsenal vs Manchester United") do
    {
      "/images/football-logos/logos/England - Premier League/Arsenal FC.png",
      "/images/football-logos/logos/England - Premier League/Manchester United.png"
    }
  end

  defp get_logos_path("Juventus vs Napoli") do
    {
      "/images/football-logos/logos/Italy - Serie A/Juventus FC.png",
      "/images/football-logos/logos/Italy - Serie A/SSC Napoli.png"
    }
  end

  defp get_logos_path("PSG vs Marseille") do
    {
      "/images/football-logos/logos/France - Ligue 1/Paris Saint-Germain.png",
      "/images/football-logos/logos/France - Ligue 1/Olympique Marseille.png"
    }
  end

  defp get_logos_path("Atletico Madrid vs Sevilla") do
    {
      "/images/football-logos/logos/Spain - LaLiga/Atlético de Madrid.png",
      "/images/football-logos/logos/Spain - LaLiga/Sevilla FC.png"
    }
  end

  defp get_logos_path("Bayern Munich vs Borussia Dortmund") do
    {
      "/images/football-logos/logos/Germany - Bundesliga/Bayern Munich.png",
      "/images/football-logos/logos/Germany - Bundesliga/Borussia Dortmund.png"
    }
  end

  defp get_logos_path(_), do: {nil, nil}
end
