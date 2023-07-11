defmodule QDSP.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      QDSPWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: QDSP.PubSub},
      # Start Finch
      {Finch, name: QDSP.Finch},
      # Cache
      {Cachex, name: :question_cache},
      {QDSP.Bot.Index, name: QDSP.Bot.Index},
      {Redix, name: :cache, host: redis_host(), port: redis_port()},
      # Start the Endpoint (http/https)
      QDSPWeb.Endpoint
      # Start a worker by calling: QDSP.Worker.start_link(arg)
      # {QDSP.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: QDSP.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    QDSPWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp redis_host(), do: Application.get_env(:qdsp, :redis_host)
  defp redis_port(), do: Application.get_env(:qdsp, :redis_port)
end
