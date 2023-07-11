defmodule QDSPWeb.AskControllerTest do
  use QDSPWeb.ConnCase

  describe "ask" do
    test "responds questions", %{conn: conn} do
      QDSP.OpenAi.Mock
      |> Mox.expect(:chat_completion, fn _, _ ->
        {:ok,
         """
         podemos: prohibirá la tortilla de patata sin cebolla
         """}
      end)
      |> Mox.expect(:embeddings, fn ["medidas y propuestas sobre la tortilla de patata"] ->
        {:ok, [[0, 0.2, 0.2]]}
      end)

      conn = post(conn, ~p"/api/ask", %{q: "la tortilla de patata"})

      assert json_response(conn, 200) == %{
               "podemos" => %{
                 "result" => "prohibirá la tortilla de patata sin cebolla",
                 "context" => nil
               }
             }
    end

    test "caches answers when it's configured", %{conn: conn} do
      Application.put_env(:qdsp, :cache_enabled, true)

      on_exit(fn ->
        Application.put_env(:qdsp, :cache_enabled, false)
      end)

      QDSP.OpenAi.Mock
      |> Mox.expect(:chat_completion, fn _, _ ->
        {:ok,
         """
         podemos: prohibirá la tortilla de patata sin cebolla
         """}
      end)
      |> Mox.expect(:embeddings, fn ["medidas y propuestas sobre la tortilla de patata"] ->
        {:ok, [[0, 0.2, 0.2]]}
      end)

      conn = post(conn, ~p"/api/ask", %{q: "la tortilla de patata"})

      assert json_response(conn, 200) == %{
               "podemos" => %{
                 "result" => "prohibirá la tortilla de patata sin cebolla",
                 "context" => nil
               }
             }

      conn = post(conn, ~p"/api/ask", %{q: "la tortilla de patata"})

      assert conn.status == 200
    end

    test "retuns error when query is longer than 60 chars", %{conn: conn} do
      conn =
        post(conn, ~p"/api/ask", %{
          q:
            "esta es una pregunta largaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
        })

      assert json_response(conn, 400)
    end
  end
end
