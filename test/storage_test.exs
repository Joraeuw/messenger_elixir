defmodule StorageTest do
  use ExUnit.Case
  doctest Messenger

  defp create_two_users() do
    first_user =
      Storage.Users.register(
        "jora",
        "joraeuw@gmail.com",
        "password",
        "The darkest minds tend to hide behind the most unlikely faces"
      )

    second_user =
      Storage.Users.register(
        "ivo",
        "ivo@gmail.com",
        "password1",
        "Simp"
      )

    first_user = hd(Database.User.match!(email: "joraeuw@gmail.com", password: "password").values)
    second_user = hd(Database.User.match!(email: "ivo@gmail.com", password: "password1").values)

    {Storage.Users.construct_user_p(first_user), Storage.Users.construct_user_p(second_user)}
  end

  defp create_four_users() do
    first_user =
      Storage.Users.register(
        "jora",
        "joraeuw@gmail.com",
        "password",
        "The darkest minds tend to hide behind the most unlikely faces"
      )

    second_user =
      Storage.Users.register(
        "ivo",
        "ivo@gmail.com",
        "password1",
        "Simp"
      )

    third_user =
      Storage.Users.register(
        "doby",
        "doby@gmail.com",
        "password2",
        "I could"
      )

    fourth_user =
      Storage.Users.register(
        "MagicMike",
        "magic_mikie@gmail.com",
        "password3",
        "I couldn't"
      )

    first_user = hd(Database.User.match!(email: "joraeuw@gmail.com", password: "password").values)
    second_user = hd(Database.User.match!(email: "ivo@gmail.com", password: "password1").values)
    third_user = hd(Database.User.match!(email: "doby@gmail.com", password: "password2").values)

    fourth_user =
      hd(Database.User.match!(email: "magic_mikie@gmail.com", password: "password3").values)

    {Storage.Users.construct_user_p(first_user), Storage.Users.construct_user_p(second_user),
     Storage.Users.construct_user_p(third_user), Storage.Users.construct_user_p(fourth_user)}
  end

  test "creates user" do
    Storage.Users.remove_all()

    {:ok, :registered} =
      Storage.Users.register(
        "jora",
        "joraeuw@gmail.com",
        "password",
        "The darkest minds tend to hide behind the most unlikely faces"
      )

    user =
      hd(Database.User.match!(email: "joraeuw@gmail.com", password: "password").values)
      |> Storage.Users.construct_user_p()

    assert user == Storage.Users.get(user.id)
  end

  test "sends a friend request" do
    Storage.Users.remove_all()

    {first_user, second_user} = create_two_users()
    Storage.Users.request_friendship(first_user.id, second_user.id)
    first_user = Storage.Users.get(first_user.id)
    second_user = Storage.Users.get(second_user.id)

    assert List.keyfind(first_user.pending_friend_requests, second_user.id, 0, nil) ==
             {second_user.id, :from_self} &&
             List.keyfind(second_user.pending_friend_requests, first_user.id, 0, nil) ==
               {first_user.id, :from_sender}
  end

  test "accepts a friend request" do
    Storage.Users.remove_all()

    {first_user, second_user} = create_two_users()
    Storage.Users.request_friendship(first_user.id, second_user.id)
    Storage.Users.accept_friend_request(second_user.id, first_user.id)
    first_user = Storage.Users.get(first_user.id)
    second_user = Storage.Users.get(second_user.id)

    assert Enum.member?(first_user.friends_ids, second_user.id) &&
             Enum.member?(second_user.friends_ids, first_user.id)
  end

  test "gets props" do
    Storage.Users.remove_all()

    {:ok, :registered} =
      Storage.Users.register(
        "jora",
        "joraeuw@gmail.com",
        "password",
        "The darkest minds tend to hide behind the most unlikely faces"
      )

    user =
      hd(Database.User.match!(email: "joraeuw@gmail.com", password: "password").values)
      |> Storage.Users.construct_user_p()

    assert Storage.Users.get_props(user.id, [:id, :username, :email]) == %{
             id: user.id,
             username: user.username,
             email: user.email
           }
  end

  test "deny friend request" do
    Storage.Users.remove_all()

    {first_user, second_user} = create_two_users()
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
    Storage.Users.remove_all()

    {first_user, second_user} = create_two_users()
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
    Storage.Users.remove_all()

    {first_user, second_user} = create_two_users()
    Storage.Users.request_friendship(first_user.id, second_user.id)
    Storage.Users.accept_friend_request(second_user.id, first_user.id)

    assert Storage.Users.are_friends?(first_user.id, second_user.id) == true

    Storage.Users.remove_friend(first_user.id, second_user.id)
    assert Storage.Users.are_friends?(first_user.id, second_user.id) == false
  end

  test "deletes user" do
    Storage.Users.remove_all()

    {:ok, :registered} =
      Storage.Users.register(
        "jora",
        "joraeuw@gmail.com",
        "password",
        "The darkest minds tend to hide behind the most unlikely faces"
      )

    user =
      hd(Database.User.match!(email: "joraeuw@gmail.com", password: "password").values)
      |> Storage.Users.construct_user_p()

    Storage.Users.delete(user.id)

    assert Storage.Users.get(user.id) == :not_found
  end

  test "reads friends" do
    Storage.Users.remove_all()

    {first_user, second_user, third_user, fourth_user} = create_four_users()
    Storage.Users.request_friendship(first_user.id, second_user.id)
    Storage.Users.accept_friend_request(second_user.id, first_user.id)
    Storage.Users.request_friendship(fourth_user.id, first_user.id)
    Storage.Users.accept_friend_request(first_user.id, fourth_user.id)
    Storage.Users.request_friendship(third_user.id, fourth_user.id)
    Storage.Users.accept_friend_request(fourth_user.id, third_user.id)
    second_user = Storage.Users.get(second_user.id)
    fourth_user = Storage.Users.get(fourth_user.id)

    assert match?([second_user, fourth_user], Storage.Users.read_friends(first_user.id))
    assert match?([third_user, first_user], Storage.Users.read_friends(fourth_user.id))
  end

  test "reads non-friend users" do
    Storage.Users.remove_all()

    {first_user, second_user, third_user, fourth_user} = create_four_users()
    Storage.Users.request_friendship(first_user.id, third_user.id)
    Storage.Users.accept_friend_request(third_user.id, first_user.id)

    assert Enum.sort([Storage.Users.get(fourth_user.id), Storage.Users.get(second_user.id)]) ==
             Storage.Users.read_users(first_user.id) |> Enum.sort()
  end

  test "sends a message to a friend / adds a pending message" do
    Storage.Users.remove_all()
    {first_user, second_user} = create_two_users()
    Storage.Users.request_friendship(first_user.id, second_user.id)
    Storage.Users.accept_friend_request(second_user.id, first_user.id)

    msg = Storage.Messages.add(first_user.id, second_user.id, "Hello!")

    %{pending_messages: pending_msgs} =
      Storage.Users.get_props(second_user.id, [:pending_messages])

    assert Enum.member?(pending_msgs, msg.message_id)
  end

  test "removes pending messages" do
    Storage.Users.remove_all()
    {first_user, second_user} = create_two_users()
    Storage.Users.request_friendship(first_user.id, second_user.id)
    Storage.Users.accept_friend_request(second_user.id, first_user.id)

    msg = Storage.Messages.add(first_user.id, second_user.id, "Hello!")
    _msg2 = Storage.Messages.add(first_user.id, second_user.id, "How ya doin'?")

    %{pending_messages: pending_msgs} =
      Storage.Users.get_props(second_user.id, [:pending_messages])

    Storage.Users.remove_pending_messages(second_user.id, pending_msgs)

    %{pending_messages: pending_msgs} =
      Storage.Users.get_props(second_user.id, [:pending_messages])

    assert !Enum.member?(pending_msgs, msg.message_id)
  end
  
end
