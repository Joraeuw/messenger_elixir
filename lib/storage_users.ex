defmodule Storage.Users do
  require Amnesia
  require Amnesia.Helper
  require Exquisite
  require Database.User

  alias Database.User

  def get_by_credentials(username, password, props) do
    user = User.match!(username: username, hashed_password: :crypto.hash(:sha256, password))

    construct_user_p(hd(user.values)) |> get_props(props)
  end

  def register(username, email, password, bio) do
    user_id = "#{username}&#{Enum.random(1_000..9_999)}"

    case get(user_id) do
      %User{} ->
        register(username, email, password, bio)

      :not_found ->
        Amnesia.transaction do
          %User{
            id: user_id,
            username: username,
            email: email,
            bio: bio,
            hashed_password: :crypto.hash(:sha256, password),
            friends_ids: [],
            pending_messages: [],
            pending_friend_requests: [],
            time_created: System.os_time()
          }
          |> User.write()
        end
    end
    |> case do
      %User{} ->
        {:ok, :registered}

      other ->
        {:error, other}
    end
  end

  def get(id) do
    Amnesia.transaction do
      User.read(id)
    end
    |> case do
      %User{} = user ->
        user

      _ ->
        :not_found
    end
  end

  def get_props(self_id, props) when is_struct(self_id, User) do
    Map.take(self_id, props)
  end

  def get_props(self_id, props) do
    Map.take(get(self_id), props)
  end

  def request_friendship(self_id, friend_id) do
    with %User{} = self <-
           get(self_id),
         %User{} = friend <-
           get(friend_id) do
      {Amnesia.transaction do
         Map.update!(self, :pending_friend_requests, &[{friend_id, :from_self} | &1])
         |> User.write()
       end,
       Amnesia.transaction do
         Map.update!(friend, :pending_friend_requests, &[{self_id, :from_sender} | &1])
         |> User.write()
       end}
      |> case do
        {%User{}, %User{}} -> {:ok, :accepted}
        other -> {:error, other}
      end
    end
  end

  def remove_friend(self_id, friend_id) do
    remove_friend_p(self_id, friend_id)
    remove_friend_p(friend_id, self_id)
  end

  defp remove_friend_p(self_id, friend_id) do
    Amnesia.transaction do
      usr = get(friend_id)

      Map.replace!(usr, :friends_ids, Enum.filter(usr.friends_ids, &(&1 != self_id)))
      |> User.write()
    end
  end

  def are_friends?(usera_id, userb_id) do
    Enum.member?(get(usera_id).friends_ids, userb_id) &&
      Enum.member?(get(userb_id).friends_ids, usera_id)
  end

  def accept_friend_request(self_id, friend_id) do
    Enum.member?(get(self_id).pending_friend_requests, {friend_id, :from_sender})
    |> case do
      true ->
        {add_friend(self_id, friend_id), add_friend(friend_id, self_id)}
        |> case do
          {%User{}, %User{}} -> {:ok, :accepted}
          other -> {:error, other}
        end

      false ->
        {:error, :no_such_friend}
    end
  end

  def delete_friend_request(self_id, friend_id) do
    delete_frined_request_p(self_id, friend_id)
    delete_frined_request_p(friend_id, self_id)
  end

  def add_pending_message(self_id, message_id) do
    Amnesia.transaction do
      Map.update!(get(self_id), :pending_messages, &[message_id | &1])
      |> User.write()
    end
  end

  def remove_pending_messages(self_id, message_ids) when is_list(message_ids) do
    Amnesia.transaction do
      Map.update!(
        get(self_id),
        :pending_messages,
        &Enum.reject(&1, fn msg -> msg in message_ids end)
      )
      |> User.write()
    end
  end

  def remove_pending_messages(self_id, message_id) do
    Amnesia.transaction do
      Map.update!(get(self_id), :pending_messages, &List.delete(&1, message_id))
      |> User.write()
    end
  end

  def delete(self_id) do
    Amnesia.transaction do
      User.delete(self_id)
    end
  end

  def read_pending_messages(self_id, sender_id) do
    messages = change_status_of_pending(self_id, sender_id, :seen)
    remove_pending_messages(self_id, &Enum.map(&1, fn message -> message.message_id end))
    messages
  end

  def receive_pending_messages(self_id, sender_id) do
    change_status_of_pending(self_id, sender_id, :received)
  end

  defp change_status_of_pending(self_id, sender_id, status) when status in [:received, :seen] do
    %{pending_messages: messages} = get_props(self_id, [:pending_messages])

    Enum.map(
      messages,
      &Storage.Messages.get_props(&1, [
        :message_id,
        :message,
        :sender_id,
        :recipient_id,
        :time_sent,
        :last_edit,
        :time_seen,
        :status,
        :can_see
      ])
    )
    |> Enum.filter(fn msg ->
      cond do
        msg.sender_id == sender_id && msg.can_see in [:recipient, :all] ->
          Storage.Messages.change_status(msg.message_id, status)
          true

        true ->
          false
      end
    end)
  end

  #! READS
  def read_all do
    Amnesia.transaction do
      User.foldl([], &[construct_user_p(&1) | &2])
    end
  end

  def read_friends(self_id) do
    get(self_id)
    |> Map.get(:friends_ids, [])
    |> then(
      &for friend_id <- &1 do
        get(friend_id)
      end
    )
  end

  def remove_all do
    User.clear()
  end

  def read_users(self_id) do
    [self_id | Map.get(get(self_id), :friends_ids, [])]
    |> then(
      &for friend_id <- &1 do
        get(friend_id)
      end
    )
    |> then(&(read_all() -- &1))
  end

  # PRIVATES
  defp add_friend(self_id, friend_id) do
    Amnesia.transaction do
      Map.update!(get(self_id), :pending_friend_requests, fn pending_friend_requests ->
        List.keydelete(pending_friend_requests, friend_id, 0)
      end)
      |> Map.update!(:friends_ids, &[friend_id | &1])
      |> User.write()
    end
  end

  defp delete_frined_request_p(self_id, friend_id) do
    Amnesia.transaction do
      Map.update!(get(self_id), :pending_friend_requests, fn pending_friend_requests ->
        List.keydelete(pending_friend_requests, friend_id, 0)
      end)
      |> User.write()
    end
  end

  def construct_user_p(
        {Database.User, id, username, email, bio, password, pending_messages, friends_ids,
         pending_req, time_created}
      ) do
    %User{
      id: id,
      username: username,
      email: email,
      bio: bio,
      hashed_password: password,
      pending_messages: pending_messages,
      friends_ids: friends_ids,
      pending_friend_requests: pending_req,
      time_created: time_created
    }
  end
end
