defmodule Example do
  require Logger
  use Application

  def start(_type, _args) do
    port = Application.get_env(:example, :door_camera_bot, 4000)

    children = [
      Plug.Adapters.Cowboy.child_spec(:http, Example.Router, [], port: port)
    ]

    Logger.info "Started application"

    Supervisor.start_link(children, strategy: :one_for_one)

    IO.gets ""
    Logger.info "Exiting..."
  end
end
