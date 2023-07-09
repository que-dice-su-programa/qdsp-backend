defmodule QDSP.Bot.Index do
  use GenServer

  alias QDSP.Bot.Parser

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def get_data() do
    GenServer.call(__MODULE__, :get_data)
  end

  def init(_args) do
    {:ok, load_data_from_file()}
  end

  def get() do
    GenServer.call(__MODULE__, :get_data)
  end

  def handle_call(:get_data, _from, state) do
    {:reply, state, state}
  end

  defp load_data_from_file() do
    %{
      sumar: "priv/embeddings/sumar.csv" |> File.read!() |> Parser.parse(),
      psoe: "priv/embeddings/psoe.csv" |> File.read!() |> Parser.parse(),
      vox: "priv/embeddings/vox.csv" |> File.read!() |> Parser.parse(),
      pp: "priv/embeddings/pp.csv" |> File.read!() |> Parser.parse()
    }
  end
end
