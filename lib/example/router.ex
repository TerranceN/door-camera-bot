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
  defstruct [:message, :sender]
end

defmodule Message do
  @derive [Poison.Encoder]
  defstruct [:seq, :text, :attachments]
end

defmodule User do
  @derive [Poison.Encoder]
  defstruct [:id]
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
            result = Poison.decode(json_string, as: %Response{entry: [%Entry{messaging: [%MessageRepr{message: %Message{}, sender: %User{}}]}]})
            case result do
              {:ok, %Response{entry: nil}} -> nil
              {:ok, json_structs} ->
                if Map.has_key?(json_structs, :entry) do
                  messaging = hd(hd(json_structs.entry).messaging)
                  Logger.info "received text \"#{messaging.message.text}\""
                  spawn sendfn(messaging.sender.id, messaging.message.text)
                end
              _ -> nil
            end

            send_resp(conn, 200, json_string)
    end
  end

  def sendfn(userId, message) do
    page_access_token = Application.get_env(:door_camera_bot, :page_access_token)
    fn ->
      Logger.info "Reply[to #{userId}]: #{message}"

      url = "https://graph.facebook.com/v2.6/me/messages?access_token=#{page_access_token}"
      json = %{recipient: %{id: userId}, message: %{text: message}}
      headers = ["Content-Type": "application/json"]
      response = HTTPotion.post url, [body: Poison.encode!(json), headers: headers]
      Logger.info response.body
    end
  end

  get "/", do: send_resp(conn, 200, "Welcome")
  match _, do: send_resp(conn, 404, "Oops!")
end
