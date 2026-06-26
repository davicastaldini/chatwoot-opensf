module Opensf
  class ConversationScope
    def initialize(conversations, user, account)
      @conversations = conversations
      @user = user
      @account = account
    end

    def perform
      role = OpensfAgentRole.find_by(user: @user, account: @account)
      return nil if role.nil? # not an opensf-managed user, fall through to default

      case role.role
      when 'manager'
        @conversations
      when 'supervisor'
        @conversations.where(inbox_id: member_inbox_ids)
      when 'vendor'
        @conversations
          .where(inbox_id: member_inbox_ids)
          .where('conversations.assignee_id = ? OR conversations.assignee_id IS NULL', @user.id)
      end
    end

    def self.broadcast_recipient?(user, conversation)
      role = OpensfAgentRole.find_by(user: user, account: conversation.account)
      return true if role.nil? # no opensf role, default behavior

      case role.role
      when 'manager'
        true
      when 'supervisor'
        user.inbox_members.exists?(inbox_id: conversation.inbox_id)
      when 'vendor'
        user.inbox_members.exists?(inbox_id: conversation.inbox_id) &&
          (conversation.assignee_id == user.id || conversation.assignee_id.nil?)
      end
    end

    private

    def member_inbox_ids
      @member_inbox_ids ||= @account.inboxes
                                    .joins(:inbox_members)
                                    .where(inbox_members: { user_id: @user.id })
                                    .pluck(:id)
    end
  end
end
