defmodule Messanger.Router do
  use Plug.Router
  require Logger

  plug(Corsica, origins: "http://localhost:3000", allow_headers: ["Authorization", "Content-type"])

  plug(:match)
  plug(:dispatch)

  post "/register" do
    {:ok, jbody, conn} = read_body(conn)
    {:ok, body} = JSON.decode(jbody)

    {:ok, :registered} =
      Storage.Users.register(body["username"], body["email"], body["password"], body["bio"])

    send_resp(conn, 201, "successful registration")
  end

  post "/login" do
    with {email, pass} <- Plug.BasicAuth.parse_basic_auth(conn),
         {:ok, _user} <- Storage.Users.login(email, pass) do
      send_resp(conn, 200, "Authorized")
    else
      {:error, :too_many_attempts} ->
        send_resp(conn, 401, "Too many attempts. Wait for a minute.")

      {:error, :unauthorized} ->
        send_resp(conn, 401, "Unauthorized")

      error ->
        IO.inspect(error)
        send_resp(conn, 500, "Internal server error")
    end
  end

  forward("/", to: Messanger.Router.Secure)
end
