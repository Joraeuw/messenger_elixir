defmodule Storage.Messages do
  require Amnesia
  require Amnesia.Helper
  require Exquisite
  require Database.Message

  alias Database.Message

  def add(self_id, recipient_id, message) do
    time = Time.utc_now()

    Storage.Users.are_friends?(self_id, recipient_id)
    |> if do
      message_id = UUID.uuid1()

      Storage.Users.add_pending_message(recipient_id, message_id)

      Amnesia.transaction do
        %Message{
          message_id: message_id,
          message: message,
          sender_id: self_id,
          recipient_id: recipient_id,
          time_sent: time,
          last_edit: time,
          time_seen: 0,
          status: :sent,
          can_see: :all
        }
        |> Message.write()
      end
    end
  end

  def get(id) do
    Amnesia.transaction do
      Message.read(id)
    end
    |> case do
      %Message{} = msg ->
        msg

      _ ->
        :not_found
    end
  end

  def edit(editor_id, message_id, message) do
    msg = get(message_id)

    Application.get_env(:amnesia, :edit_after, 0)
    |> then(
      &if Time.compare(Time.add(msg.last_edit, &1, :minute), Time.utc_now()) == :gt &&
            msg.sender_id == editor_id do
        Amnesia.transaction do
          Map.replace(msg, :message, message)
          |> Map.replace(:last_edit, Time.utc_now())
          |> Message.write()
        end
      end
    )
  end

  def unsend(self_id, message_id) do
    msg = get(message_id)

    Application.get_env(:amnesia, :unsend_after, 0)
    |> then(
      &if msg.sender_id == self_id &&
            Time.compare(Time.add(msg.time_sent, &1, :minute), Time.utc_now()) == :gt &&
            msg.status != :seen do
        Amnesia.transaction do
          Message.delete(message_id)
        end

        Storage.Users.remove_pending_messages(msg.recipient_id, message_id)
      end
    )
  end

  def change_status(self_id, status) when status in [:received, :seen] do
    Amnesia.transaction do
      case status do
        :received ->
          get(self_id) |> Map.replace!(:status, :received) |> Message.write()

        :seen ->
          get(self_id)
          |> Map.replace!(:status, :seen)
          |> Map.replace!(:time_seen, Time.utc_now())
          |> Message.write()
      end
    end
  end

  def delete_for_you(user_id, message_id) do
    Amnesia.transaction do
      msg = get(message_id)

      cond do
        (msg.sender_id == user_id && msg.can_see == :recipient) ||
            (msg.recipient_id == user_id && msg.can_see == :sender) ->
          :remove

        msg.sender_id == user_id ->
          :recipient

        msg.recipient_id == user_id ->
          :sender
      end
      |> case do
        :remove ->
          Message.delete(msg.message_id)

        can_see ->
          Map.replace!(msg, :can_see, can_see) |> Message.write()
      end
    end
  end

  def get_props(message_id, props) do
    Map.take(get(message_id), props)
  end

  def read_all(self_id, sender_id) do
    with first <- Message.match!(sender_id: self_id, recipient_id: sender_id),
         second <-
           Message.match!(sender_id: sender_id, recipient_id: self_id) do
      case {first, second} do
        {nil, nil} -> []
        {_, nil} -> first.values
        {nil, _} -> second.values
        _ -> Enum.concat(first.values, second.values)
      end
    end
    |> filter_messages(self_id)
    |> Enum.map(&construct_message/1)
  end

  def remove_messages_between(self_id, sender_id) do
    with first <- Message.match!(sender_id: self_id, recipient_id: sender_id),
         second <-
           Message.match!(sender_id: sender_id, recipient_id: self_id) do
      case {first, second} do
        {nil, nil} -> []
        {_, nil} -> first.values
        {nil, _} -> second.values
        _ -> Enum.concat(first.values, second.values)
      end
    end
    |> Enum.map(&construct_message/1)
    |> Enum.each(&Message.delete(&1.message_id))
  end

  def filter_messages(messages, self_id) do
    Enum.filter(messages, fn message ->
      message = construct_message(message)

      case {message.sender_id, message.can_see} do
        {^self_id, can_see} when can_see in [:all, :sender] ->
          true

        _ ->
          false
      end or
        case {message.recipient_id, message.can_see} do
          {^self_id, can_see} when can_see in [:all, :recipient] ->
            true

          _ ->
            false
        end
    end)
  end

  def read_all do
    Amnesia.transaction do
      Message.foldl([], &[construct_message(&1) | &2])
    end
  end

  def remove_all do
    Message.clear()
  end

  def construct_message(
        {Database.Message, message_id, message, sender_id, recipient_id, time_sent, last_edit,
         time_seen, status, can_see}
      ) do
    %Message{
      message_id: message_id,
      message: message,
      sender_id: sender_id,
      recipient_id: recipient_id,
      time_sent: time_sent,
      last_edit: last_edit,
      time_seen: time_seen,
      status: status,
      can_see: can_see
    }
  end
end
