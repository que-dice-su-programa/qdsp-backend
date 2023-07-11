defmodule QDSPWeb.AskController do
  use QDSPWeb, :controller

  alias QDSP.Cache

  require Logger

  def ask(conn, params) do
    question = Map.get(params, "q")

    with :ok <- valid_question(question),
         {:ok, response} = cached(question, fn -> QDSP.Bot.assist(question) end) do
      conn
      |> put_resp_content_type("application/json")
      |> send_resp(:ok, Jason.encode!(response))
    else
      {:error, error} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(error, Jason.encode!(%{}))
    end
  end

  def cached(key, fun) do
    case Cache.Redis.get(key) do
      {:ok, nil} ->
        with {:ok, value} <- fun.() do
          Cache.Redis.set(key, value)
          {:ok, value}
        end

      {:ok, value} ->
        {:ok, value}

      {:error, e} ->
        Logger.error(e)

        fun.()
    end
  end

  defp valid_question(question) do
    if String.length(question) > 60 do
      {:error, :bad_request}
    else
      :ok
    end
  end
end
