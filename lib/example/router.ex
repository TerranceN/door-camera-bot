defmodule Example.Router do
  require Logger
  use Plug.Router

  plug Plug.Parsers, parsers: [:urlencoded, :json],
                     pass:  ["*/*"],
                     json_decoder: Poison

  plug :match
  plug :dispatch

  match "/json_test" do
    conn = Plug.Conn.fetch_query_params(conn)
    #json = %{person: %{name: "Devin Torres", age: 27}}
    #json = Plug.Parsers.parse(conn, "application/json", "json", [])
    #json = Plug.params
    json = conn.params
    json_string = Poison.encode!(json)

    Logger.info json_string

    send_resp(conn, 200, json_string)
  end

  get "/", do: send_resp(conn, 200, "Welcome")
  match _, do: send_resp(conn, 404, "Oops!")
end
