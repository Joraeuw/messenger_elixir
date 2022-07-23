use Amnesia

defdatabase Database do
  deftable(
    User,
    [
      :id,
      :username,
      :email,
      :bio,
      :hashed_password,
      :pending_messages,
      :friends_ids,
      # {sender_id | self.id, :from_sender | from_self}
      :pending_friend_requests
    ],
    type: :set
  )

  deftable(
    Message,
    [:message_id, :message, :sender_id, :recipient_id, :time_sent, :time_seen, :status],
    type: :bag
  )
end
