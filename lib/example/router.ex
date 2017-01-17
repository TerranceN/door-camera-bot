defmodule TextMessage do
  defstruct seq: nil, text: nil
end

defmodule Response do
  @derive [Poison.Encoder]
  defstruct [:object, :entry]
end

defmodule Entry do
  @derive [Poison.Encoder]
  defstruct [:time, :messaging, :id]
end

defmodule MessageRepr do
  @derive[Poison.Encoder]
  defstruct [:message]
end

defmodule Message do
  @derive [Poison.Encoder]
  defstruct [:seq, :text, :attachments]
end

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
    json = conn.params
    case json do
        %{"hub.challenge" => challenge} ->
            send_resp(conn, 200, challenge)
        _ ->
            json_string = Poison.encode!(json)
            result = Poison.decode(json_string, as: %Response{entry: [%Entry{messaging: [%MessageRepr{message: %Message{text: nil}}]}]})
            case result do
              {:ok, %Response{entry: nil}} -> nil
              {:ok, json_structs} ->
                if Map.has_key?(json_structs, :entry) do
                  Logger.info hd(hd(json_structs.entry).messaging).message.text
                end
              _ -> nil
            end

            send_resp(conn, 200, json_string)
    end
  end

  get "/", do: send_resp(conn, 200, "Welcome")
  match _, do: send_resp(conn, 404, "Oops!")
end
