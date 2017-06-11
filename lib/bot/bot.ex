defmodule Spotiuribot.Bot do
  @bot :spotiuri_bot

  def bot(), do: @bot

  use Telex.Bot,
    name: @bot,
    middlewares: [Spotiauth]
  use Telex.Dsl

  require Logger

  defp get_url(url, token) do
    HTTPotion.get(url, [headers: ["Authorization": "Bearer #{token}"]])
  end

  def urimatch(s) do
    case Regex.run(~r{spotify:(track|album):([a-zA-Z0-9]+)}, s) do
      nil -> :error
      [_, type, id] -> {:ok, type, id}
    end
  end

  def getdata(x, id, token) when x == "album" or x == "track" do
    uri = "https://api.spotify.com/v1/#{x}s/#{id}"
    case get_url(uri, token).body |> Poison.decode do
      {:ok, %{"artists" => [%{"name" => artistname} | _ ], "album" => %{"name" => albumname}, "name" => trackname}} ->
        {:ok, "🎤 Artist: #{artistname} \n💽 Album: #{albumname} \n📝 Track: #{trackname}", "https://open.spotify.com/track/#{id}"}
      {:ok, %{"artists" => [%{"name" => artistname} | _ ], "name" => albumname}} ->
        {:ok, "🎤 Artist: #{artistname} \n💽 Album: #{albumname}", "https://open.spotify.com/album/#{id}"}
      _ -> {:error, "Unknown URI: #{id}"}
    end
  end
  def getdata(_, _, _), do: "guat is dis"

  def create_inline_button(row) do
    row
    |> Enum.map(fn ops ->
      Map.merge(%Telex.Model.InlineKeyboardButton{}, Enum.into(ops, %{})) end)
  end

  def create_inline(data \\ [[]]) do
    data =
      data
      |> Enum.map(&create_inline_button/1)

    %Telex.Model.InlineKeyboardMarkup{inline_keyboard: data}
  end

  def generate_url_button(url) do
    create_inline [[[text: "Open in Spotify", url: url]]]
  end

  def handle({:command, "help", msg}, name, _) do
    answer msg, "Toma esta halluda!", bot: name
  end

  def handle({_, _, %{text: t, message_id: mid} = msg}, name, %{token: token}) do
    with {:ok, type, id} <- urimatch(t),
         {:ok, text, url} <- getdata(type, id, token),
           markup <- generate_url_button(url) do
      answer msg, text, bot: name, reply_to_message_id: mid, reply_markup: markup
   # Uncomment for debug
   # else
   #   err -> Logger.warn(inspect err)
  end
end
end
