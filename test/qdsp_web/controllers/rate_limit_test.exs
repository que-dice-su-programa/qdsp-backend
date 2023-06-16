defmodule QDSPWeb.RateLimitTest do
  use QDSPWeb.ConnCase

  describe "rate limit" do
    test "only allows 2 requests per 10 seconds", %{conn: conn} do
      QDSP.OpenAi.Mock
      |> Mox.expect(:chat_completion, 2, fn _, _ ->
        {:ok,
         """
         podemos: prohibirá la tortilla de patata sin cebolla
         """}
      end)
      |> Mox.expect(:embeddings, 2, fn ["la tortilla de patata"] ->
        {:ok, [[0, 0.2, 0.2]]}
      end)

      conn = post(conn, ~p"/api/ask", %{q: "la tortilla de patata"})
      assert conn.status == 200

      conn = post(conn, ~p"/api/ask", %{q: "la tortilla de patata"})
      assert conn.status == 200

      conn = post(conn, ~p"/api/ask", %{q: "la tortilla de patata"})
      assert conn.status == 429
    end
  end
end
