defmodule Spotiuribot do
  use Application
  def start, do: start(1, 1)

  require Logger
  
  def start(_, _) do
    import Supervisor.Spec
    
    children = [
      supervisor(Telex, []),
      supervisor(Spotiuribot.Bot, [:updates, Application.get_env(:spotiuri_bot, :token)])
    ]

    opts = [strategy: :one_for_one, name: Spotiuribot]
    case Supervisor.start_link(children, opts) do
      {:ok, _} = ok ->
        Logger.info "Starting SpotiUribot"
        ok
      error ->
        Logger.error "Error starting SpotiUriBot"
        error
    end
  end
end
