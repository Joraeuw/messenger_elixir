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
         {%Database.User{} = user, flag} <- Storage.Users.exists?(email, pass),
         :ok <- Storage.Users.attempt_manager(user, flag) do
      Storage.Users.reset_attempts(user)
      send_resp(conn, 200, "Authorized")
    else
      {:set_attempt_time, user} ->
        Storage.Users.set_next_attempt_time(user)
        |> Storage.Users.reset_attempts()

        send_resp(conn, 401, "Too many attempts. Wait for a minute.")

      :too_many_attempts ->
        send_resp(conn, 401, "Too many attempts. Wait for a minute.")

      _ ->
        send_resp(conn, 401, "Unauthorized")
    end
  end

  forward("/", to: Messanger.Router.Secure)
end
