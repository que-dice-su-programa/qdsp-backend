defmodule QDSPWeb.AskController do
  use QDSPWeb, :controller

  def ask(conn, params) do
    question = Map.get(params, "q")

    with {:ok, response} <- QDSP.Bot.assist(question) do
      conn
      |> put_resp_content_type("application/json")
      |> send_resp(:ok, Jason.encode!(response))
    end
  end
end
