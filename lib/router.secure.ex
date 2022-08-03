defmodule Messanger.Router.Secure do
  use Plug.Router
  # import Plug.BasicAuth
  alias Storage.Messages
  alias Storage.Users

  # plug(Plug.Parsers,
  #   parsers: [:urlencoded, :json],
  #   json_decoder: JSON
  # )

  plug(:auth)
  plug(:match)
  plug(:dispatch)

  get "/" do
    {:ok, response} = JSON.encode(conn.assigns[:current_user])
    send_resp(conn, 200, response)
  end

  get "/friends" do
    {:ok, response} =
      Users.read_friends(conn.assigns[:current_user].id)
      |> then(
        &for user <- &1 do
          Users.get_props(user, [:id, :username, :email, :bio])
        end
      )
      |> JSON.encode()

    send_resp(conn, 200, response)
  end

  get "/users" do
    {:ok, response} =
      Users.read_users(conn.assigns[:current_user].id)
      |> then(
        &for user <- &1 do
          Users.get_props(user, [:id, :username, :email, :bio])
        end
      )
      |> JSON.encode()

    send_resp(conn, 200, response)
  end

  post "/friends-add" do
    {:ok, jbody, conn} = read_body(conn)
    {:ok, body} = JSON.decode(jbody)
    Users.request_friendship(conn.assigns[:current_user].id, body["recipient_id"])
    send_resp(conn, 200, "sent")
  end

  post "/friends-accept" do
    {:ok, jbody, conn} = read_body(conn)
    {:ok, body} = JSON.decode(jbody)
    Users.accept_friend_request(conn.assigns[:current_user].id, body["sender_id"])
    send_resp(conn, 200, "accepted")
  end

  post "/friends-deny" do
    {:ok, jbody, conn} = read_body(conn)
    {:ok, body} = JSON.decode(jbody)
    Users.delete_friend_request(conn.assigns[:current_user].id, body["sender_id"])
    send_resp(conn, 200, "denied friend request")
  end

  post "/friends-remove" do
    {:ok, jbody, conn} = read_body(conn)
    {:ok, body} = JSON.decode(jbody)
    Users.remove_friend(conn.assigns[:current_user].id, body["friend_id"])
    send_resp(conn, 200, "removed friend")
  end

  get "/are-friends" do
    {:ok, jbody, conn} = read_body(conn)
    {:ok, body} = JSON.decode(jbody)

    response =
      Users.are_friends?(conn.assigns[:current_user].id, body["user_id"])
      |> to_string()

    send_resp(conn, 200, response)
  end

  post "/message/:friend_id" do
    {:ok, jbody, conn} = read_body(conn)
    {:ok, body} = JSON.decode(jbody)
    Messages.add(conn.assigns[:current_user].id, friend_id, body["message"])
    send_resp(conn, 201, "sent")
  end

  get "/message/:friend_id" do
    messages = Users.read_pending_messages(conn.assigns[:current_user].id, friend_id)
    {:ok, response} = JSON.encode(messages)
    send_resp(conn, 200, response)
  end

  get "/message/all/:friend_id" do
    messages = Storage.Messages.read_all(conn.assigns[:current_user].id, friend_id)
    {:ok, response} = JSON.encode(messages)
    send_resp(conn, 200, response)
  end

  post "/unsend-message/" do
    {:ok, jbody, conn} = read_body(conn)
    {:ok, body} = JSON.decode(jbody)

    Messages.unsend(conn.assigns[:current_user].id, body["message_id"])
    send_resp(conn, 202, "unsend")
  end

  post "/message/delete-for-you/" do
    {:ok, jbody, conn} = read_body(conn)
    {:ok, body} = JSON.decode(jbody)

    Messages.delete_for_you(conn.assigns[:current_user].id, body["message_id"])
    send_resp(conn, 202, "deleted for user")
  end

  match _ do
    send_resp(conn, 404, "404 page not found!")
  end

  defp auth(conn, _opts) do
    with {email, pass} <- Plug.BasicAuth.parse_basic_auth(conn),
         %{} = user <-
           Users.get_by_credentials(email, pass, [
             :id,
             :email,
             :bio,
             :pending_messages,
             :friends_ids,
             :pending_friend_requests,
             :time_created
           ]) do
      assign(conn, :current_user, user)
    else
      _ -> conn |> Plug.BasicAuth.request_basic_auth() |> halt()
    end
  end
end
