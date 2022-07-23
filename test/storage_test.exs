defmodule StorageTest do
  use ExUnit.Case
  doctest Messenger

  defp create_users() do
    first_user =
      Storage.Users.register_user(
        "jora",
        "joraeuw@gmail.com",
        "password",
        "The darkest minds tend to hide behind the most unlikely faces"
      )

    second_user =
      Storage.Users.register_user(
        "ivo",
        "ivo@gmail.com",
        "password1",
        "Simp"
      )

    {first_user, second_user}
  end

  test "dir set correctly" do
    assert Messenger.hello() == "../db"
  end

  test "creates user" do
    user =
      Storage.Users.register_user(
        "jora",
        "joraeuw@gmail.com",
        "password",
        "The darkest minds tend to hide behind the most unlikely faces"
      )

    assert user == Storage.Users.get_user(user.id)
  end

  test "sends a friend request" do
    {first_user, second_user} = create_users()
    Storage.Users.request_friendship(first_user.id, second_user.id)
    first_user = Storage.Users.get_user(first_user.id)
    second_user = Storage.Users.get_user(second_user.id)

    assert List.keyfind(first_user.pending_friend_requests, second_user.id, 0, nil) ==
             {second_user.id, :from_self} &&
             List.keyfind(second_user.pending_friend_requests, first_user.id, 0, nil) ==
               {first_user.id, :from_sender}
  end

  test "accepts a friend request" do
    {first_user, second_user} = create_users()
    Storage.Users.request_friendship(first_user.id, second_user.id)
    Storage.Users.accept_friend_request(second_user.id, first_user.id)
    first_user = Storage.Users.get_user(first_user.id)
    second_user = Storage.Users.get_user(second_user.id)

    assert Enum.member?(first_user.friends_ids, second_user.id) &&
             Enum.member?(second_user.friends_ids, first_user.id)
  end

  test "gets props" do
    user =
      Storage.Users.register_user(
        "jora",
        "joraeuw@gmail.com",
        "password",
        "The darkest minds tend to hide behind the most unlikely faces"
      )

    assert Storage.Users.get_props(user.id, [:id, :username, :email]) == %{
             id: user.id,
             username: user.username,
             email: user.email
           }
  end

  test "deny friend request" do
    {first_user, second_user} = create_users()
    Storage.Users.request_friendship(first_user.id, second_user.id)
    Storage.Users.delete_friend_request(second_user.id, first_user.id)

    assert Storage.Users.get_props(first_user.id, [:pending_friend_requests]) == %{
             pending_friend_requests: []
           } &&
             Storage.Users.get_props(second_user.id, [:pending_friend_requests]) == %{
               pending_friend_requests: []
             }
  end

  test "drawback friend request" do
    {first_user, second_user} = create_users()
    Storage.Users.request_friendship(first_user.id, second_user.id)
    Storage.Users.delete_friend_request(first_user.id, second_user.id)

    assert Storage.Users.get_props(first_user.id, [:pending_friend_requests]) == %{
             pending_friend_requests: []
           } &&
             Storage.Users.get_props(second_user.id, [:pending_friend_requests]) == %{
               pending_friend_requests: []
             }
  end

  test "friends recognition" do
    {first_user, second_user} = create_users()
    Storage.Users.request_friendship(first_user.id, second_user.id)
    Storage.Users.accept_friend_request(second_user.id, first_user.id)

    assert Storage.Users.are_friends?(first_user.id, second_user.id) == true

    Storage.Users.remove_friend(first_user.id, second_user.id)
    assert Storage.Users.are_friends?(first_user.id, second_user.id) == false
  end
end
