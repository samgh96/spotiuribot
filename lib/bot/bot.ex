defmodule Spotiuribot.Bot do
  @bot :spotiuri_bot

  def bot(), do: @bot

  use Telex.Bot, name: @bot
  use Telex.Dsl

  def getalbum(uri) do
    case HTTPotion.get("https://api.spotify.com/v1/albums/#{uri}").body |> Poison.decode do
      {:ok, %{"artists" => [%{"name" => artistname} | _ ], "name" => albumname}} -> "Artist: #{artistname} \nAlbum: #{albumname}\n\nURL: https://open.spotify.com/album/#{uri}"
      _ -> "Unknown URI: #{uri} ☹️"
    end
  end

  def gettrack(uri) do
    case HTTPotion.get("https://api.spotify.com/v1/tracks/#{uri}").body |> Poison.decode do
      {:ok, %{"artists" => [%{"name" => artistname} | _ ],
	      "album" => %{"name" => albumname},
	       "name" => trackname}} -> "Artist: #{artistname} \nAlbum: #{albumname} \nTrack: #{trackname}\n\nURL: https://open.spotify.com/track/#{uri}"
      _ -> "Unknown URI: #{uri} ☹️"
    end
  end
  
  def getdata(text) do
    case text do
      "album:" <> uri -> getalbum(uri)
      "track:" <> uri -> gettrack(uri)
      _ -> "guat is dis"
    end
  end
  
  def handle({:command, "help", msg}, name, _) do
    answer msg, "Toma esta halluda!", bot: name
  end

  def handle({_, _, %{text: t, message_id: mid} = msg}, name, _) do
    case t do
      "spotify:" <> type -> answer msg, getdata(type), bot: name, reply_to_message_id: mid
      _ -> ""
    end
  end
  
end
