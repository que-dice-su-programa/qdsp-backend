# credo:disable-for-next-line
defmodule QDSP.OpenAi.SuccessMock do
  @spec completions(any()) :: {:ok, String.t()} | {:error, any()}
  def completions(_options) do
    {:ok, %{choices: [%{"text" => "I complete you", "finish_reason" => "stop"}]}}
  end

  @spec chat_completion(any()) :: {:ok, map()} | {:error, any()}
  def chat_completion(_options) do
    {:ok, %{choices: [%{"message" => %{"content" => "I answer you"}, "finish_reason" => "stop"}]}}
  end
end

# credo:disable-for-next-line
defmodule QDSP.OpenAi.MockFinish do
  @spec completions(any()) :: {:ok, map()} | {:error, any()}
  def completions(_options) do
    {:ok, %{choices: [%{"text" => "I complete you", "finish_reason" => "length"}]}}
  end

  @spec chat_completion(any()) :: {:ok, map()} | {:error, any()}
  def chat_completion(_options) do
    {:ok,
     %{choices: [%{"message" => %{"content" => "I answer you"}, "finish_reason" => "length"}]}}
  end
end

# credo:disable-for-next-line
defmodule QDSP.OpenAi.MockFailure do
  @spec completions(String.t()) :: {:ok, map()} | {:error, any()}
  def completions(_options) do
    {:ok, %{choices: []}}
  end

  @spec chat_completion(String.t()) :: {:ok, map()} | {:error, any()}
  def chat_completion(_options) do
    {:ok, %{choices: []}}
  end
end

defmodule QDSP.OpenAi.ClientTest do
  use ExUnit.Case

  alias QDSP.OpenAi.Client

  describe "chat_completion/2" do
    test "returns a completion when it finishes successfully" do
      assert {:ok, "I answer you"} ==
               Client.chat_completion("answer me", [], QDSP.OpenAi.SuccessMock)
    end

    @tag :capture_log
    test "returns an error when the completion finished unsuccessfully" do
      assert {:error, "Something went wrong"} ==
               Client.chat_completion("answer me", [], QDSP.OpenAi.MockFinish)
    end

    @tag :capture_log
    test "returns an error when the completion fails" do
      assert {:error, "Something went wrong"} ==
               Client.chat_completion("answer me", [], QDSP.OpenAi.MockFailure)
    end
  end
end
