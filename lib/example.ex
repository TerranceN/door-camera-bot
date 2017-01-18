defmodule Example do
  require Logger
  use Application

  def start(_type, _args) do
    port = Application.get_env(:door_camera_bot, :cowboy_port, 4000)

    page_access_token = Application.get_env(:door_camera_bot, :page_access_token)

    if page_access_token != nil do
      children = [
        Plug.Adapters.Cowboy.child_spec(:http, Example.Router, [], port: port)
      ]
      Logger.info "Started application"

      Supervisor.start_link(children, strategy: :one_for_one)

      IO.gets ""
    else
      Logger.info "ERROR: invalid page_access_token: \"#{page_access_token}\""
    end
    
    Logger.info "Exiting..."
  end
end
