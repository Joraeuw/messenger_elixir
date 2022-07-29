defmodule Messanger.Router do
  use Plug.Router
  require Logger

  plug(:match)
  plug(:dispatch)

  post "/register" do
    {:ok, jbody, conn} = read_body(conn)
    {:ok, body} = JSON.decode(jbody)

    {:ok, :registered} =
      Storage.Users.register(body["username"], body["email"], body["password"], body["bio"])

    send_resp(conn, 201, "successful registration")
  end

  # get "/login" do
  #   # IO.inspect(read_body(conn))
  #   # Storage.Users.register()
  #   send_resp(conn, 200, conn)
  # end

  forward("/", to: Messanger.Router.Secure)
end
