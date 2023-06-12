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
      # ML model to build embeddings
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

  def nx_serving() do
    if Application.get_env(:qdsp, :embeddings_adapter) == QDSP.Bot.Embeddings.SentenceTransformers do
      {Nx.Serving,
       serving: QDSP.Bot.Embeddings.SentenceTransformers.serving(),
       name: QDSP.Bot.Embeddings.Model,
       batch_size: 8,
       batch_timeout: 100}
    else
      nil
    end
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    QDSPWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
