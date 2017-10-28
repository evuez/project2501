defmodule Project2501.Wire do
  @ids 0..4_294_967_295

  defmodule Command do
    defstruct [:message_id, :session_id, :name, {:params, %{}}]
  end

  defmodule Response do
    defstruct [:message_id, :error, :result]
  end

  def encode!(%Command{} = command) do
    message_id = Enum.random(@ids)
    {message_id, Poison.encode!(%{command | message_id: message_id})}
  end

  def decode!(response) do
    [1, message_id, error, result] = Poison.decode!(response)
    %Response{message_id: message_id, error: error, result: result}
  end
end

defimpl Poison.Encoder, for: Project2501.Wire.Command do
  def encode(%{message_id: message_id, session_id: session_id, name: name, params: params}, _opts) do
    params = Map.put(params, "sessionId", session_id)
    command = [0, message_id, "WebDriver:#{name}", params] |> Poison.encode!
    "#{String.length(command)}:#{command}"
  end
end
