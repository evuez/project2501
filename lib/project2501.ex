defmodule Project2501 do
  @moduledoc """
  Client for Marionette.

  The host and port for Marionette must be configured:

  ```
  config :project2501,
    host: 'localhost',
    port: 2828
  ```

  The server must be started before the application otherwise it'll crash.
  """

  use GenServer

  require Logger

  alias Project2501.Wire
  alias Project2501.Wire.Command
  alias Project2501.Wire.Response

  @buffer %{data: nil, expect: 0, current: 0}
  @sock_opts [:binary, active: false]

  defstruct [socket: nil, buffer: @buffer, session_id: nil, queue: %{}]

  def start_link do
    GenServer.start_link(__MODULE__, %__MODULE__{}, name: __MODULE__)
  end

  def init(state) do
    {:ok, socket} = :gen_tcp.connect(
      Application.fetch_env!(:project2501, :host),
      Application.fetch_env!(:project2501, :port),
      @sock_opts
    )

    # Create a new session
    {_, new_session} = Wire.encode!(%Command{name: "NewSession"})
    :ok = :gen_tcp.send(socket, new_session)

    {:ok, _version} = :gen_tcp.recv(socket, 0)
    {:ok, response} = :gen_tcp.recv(socket, 0)
    {response, _, _} = parse(response)
    %Response{result: %{"sessionId" => session_id}} = Wire.decode!(response)

    :inet.setopts(socket, active: true)

    {:ok, %{state | socket: socket, session_id: session_id}}
  end

  # API

  @doc """
  Sends a command to Marionette. Every command is assumed to be a WebDriver command and
  shouldn't be prefixed with `WebDriver:`.

  A `%Project2501.Wire.Response{}` struct is returned, see
  https://developer.mozilla.org/en-US/docs/Mozilla/QA/Marionette/Protocol for more
  info.

  ## Example

      iex> Project2501.order("Navigate", %{url: "http://example.org"})
      %Response{error: nil, message_id: 829347167, result: %{}}
  """
  def order(command, params \\ %{}) do
    command = %Command{name: command, params: params}

    {:ok, answer} = GenServer.call(__MODULE__, {:order, command})
    answer
  end

  # Callbacks

  def handle_call({:order, command}, from, %{queue: queue} = state) do
    {message_id, command} = Wire.encode!(%{command | session_id: state.session_id})

    :ok = :gen_tcp.send(state.socket, command)

    {:noreply, %{state | queue: Map.put(queue, message_id, from)}}
  end

  def handle_info({:tcp, _, response}, %{buffer: %{data: nil}} = state) do
    {response, expect, current} = parse(response)

    case current do
      size when size < expect ->
        {:noreply, %{state | buffer: %{
          data: response, expect: expect, current: current
        }}}
      _ -> reply(response, state)
    end
  end
  def handle_info({:tcp, _, response}, %{buffer: %{data: data, expect: expect, current: current}} = state) do
    case current + byte_size(response) do
      current when current < expect ->
        {:noreply, %{state | buffer: %{
          data: [data, response], expect: expect, current: current
        }}}
      _ -> reply([data, binary_part(response, 0, expect - current)], state)
    end
  end

  def handle_info({:tcp_closed, _port}, state) do
    Logger.warn fn -> "TCP connection closed." end
    {:stop, :tcp_closed, state}
  end

  # Helpers

  defp reply(response, %{queue: queue} = state) do
    %{message_id: message_id} = response = Wire.decode!(response)

    {client, queue} = Map.pop(queue, message_id)

    GenServer.reply(client, {:ok, response})

    {:noreply, %{state | queue: queue, buffer: @buffer}}
  end

  defp parse(response) do
    [expect, response] = String.split(response, ":", parts: 2)
    expect = String.to_integer(expect)

    {response, expect, byte_size(response)}
  end
end
