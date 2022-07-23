defmodule Storage.Users do
  require Amnesia
  require Amnesia.Helper
  require Exquisite
  require Database.User

  alias Database.User

  def register_user(username, email, password, bio) do
    Amnesia.transaction do
      %User{
        id: UUID.uuid1(),
        username: username,
        email: email,
        bio: bio,
        hashed_password: :crypto.hash(:sha256, password),
        friends_ids: [],
        pending_messages: [],
        pending_friend_requests: []
      }
      |> User.write()
    end
  end

  def get_user(id) do
    Amnesia.transaction do
      User.read(id)
    end
    |> case do
      %User{} = user ->
        user

      _ ->
        {:error, :not_found}
    end
  end

  def get_props(self_id, props) do
    Map.take(get_user(self_id), props)
  end

  def request_friendship(self_id, friend_id) do
    {Amnesia.transaction do
       Map.update!(get_user(self_id), :pending_friend_requests, &[{friend_id, :from_self} | &1])
       |> User.write()
     end,
     Amnesia.transaction do
       Map.update!(get_user(friend_id), :pending_friend_requests, &[{self_id, :from_sender} | &1])
       |> User.write()
     end}
    |> case do
      {%User{}, %User{}} -> {:ok, :accepted}
      other -> {:error, other}
    end
  end

  def read_all do
    Amnesia.transaction do
      User.foldl([], &[&1 | &2])
    end
  end

  def remove_friend(self_id, friend_id) do
    remove_friend_p(self_id, friend_id)
    remove_friend_p(friend_id, self_id)
  end

  defp remove_friend_p(self_id, friend_id) do
    Amnesia.transaction do
      usr = get_user(friend_id)

      Map.replace!(usr, :friends_ids, Enum.filter(usr.friends_ids, &(&1 != self_id)))
      |> User.write()
    end
  end

  def are_friends?(usera_id, userb_id) do
    Enum.member?(get_user(usera_id).friends_ids, userb_id) &&
      Enum.member?(get_user(userb_id).friends_ids, usera_id)
  end

  def accept_friend_request(self_id, friend_id) do
    Enum.member?(get_user(self_id).pending_friend_requests, {friend_id, :from_sender})
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

  defp add_friend(self_id, friend_id) do
    Amnesia.transaction do
      Map.update!(get_user(self_id), :pending_friend_requests, fn pending_friend_requests ->
        List.keydelete(pending_friend_requests, friend_id, 0)
      end)
      |> Map.update!(:friends_ids, &[friend_id | &1])
      |> User.write()
    end
  end

  defp delete_frined_request_p(self_id, friend_id) do
    Amnesia.transaction do
      Map.update!(get_user(self_id), :pending_friend_requests, fn pending_friend_requests ->
        List.keydelete(pending_friend_requests, friend_id, 0)
      end)
      |> User.write()
    end
  end
end
