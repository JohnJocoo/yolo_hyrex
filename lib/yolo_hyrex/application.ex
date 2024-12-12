defmodule Yolo.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  alias Yolo.MatchesPipe
  alias Yolo.MatchesStorage

  @impl true
  def start(_type, _args) do
    children = [
      YoloWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:yolo_hyrex, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Yolo.PubSub},
      MatchesStorage,
      YoloWeb.Endpoint,
      MatchesPipe
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Yolo.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    YoloWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
