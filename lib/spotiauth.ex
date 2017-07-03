defmodule Spotiauth do
  use GenServer

  require Logger

  def start_link() do
    GenServer.start_link(__MODULE__, :ok, [name: :auth])
  end

  def init(:ok) do
    Process.send_after(self(), :auth, 1_000)
    {:ok, %{}}
  end

  def token() do
    GenServer.call(:auth, :token)
  end

  # Telex middleware!
  def apply(s) do
    tok = token()
    {:ok, Map.put(s, :token, tok)}
  end

  def handle_info(:auth, _ops) do
    client_id = Config.get(:spotiuri_bot, :client_id)
    client_secret = Config.get(:spotiuri_bot, :client_secret)

    b64 = Base.encode64("#{client_id}:#{client_secret}")
    auth = "Basic #{b64}"
    case HTTPotion.post("https://accounts.spotify.com/api/token", [body: "grant_type=client_credentials", headers: ["Authorization": auth, "Content-Type": "application/x-www-form-urlencoded"]]) do
      %HTTPotion.Response{status_code: 200, body: body} ->
        %{"access_token" => actok, "expires_in" => expin} = Poison.decode!(body)
        # One second before, ask for renew
        Process.send_after(self(), :auth, (expin - 60) * 1000)
        {:noreply, %{token: actok}}
      e ->
        Logger.error "ERROR! #{inspect e}"
        raise "Not auth!"
    end
  end

  def handle_call(:token, _, %{token: token} = ops) do
    {:reply, token, ops}
  end

  def handle_call(:token, _, ops) do
    send(self(), :auth)
    {:reply, "", ops}
  end
end
