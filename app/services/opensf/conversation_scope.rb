module Opensf
  class ConversationScope
    def initialize(conversations, user, account)
      @conversations = conversations
      @user = user
      @account = account
    end

    def perform
      return nil if opensf_role.blank?

      case opensf_role
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
      role = AccountUser.find_by(user: user, account: conversation.account)&.opensf_role
      return true if role.blank?

      case role
      when 'manager'
        true
      when 'supervisor'
        user.inbox_members.exists?(inbox_id: conversation.inbox_id)
      when 'vendor'
        user.inbox_members.exists?(inbox_id: conversation.inbox_id) &&
          (conversation.assignee_id == user.id || conversation.assignee_id.nil?)
      else
        true
      end
    end

    private

    def opensf_role
      @opensf_role ||= AccountUser.find_by(user: @user, account: @account)&.opensf_role
    end

    def member_inbox_ids
      @member_inbox_ids ||= @account.inboxes
                                    .joins(:inbox_members)
                                    .where(inbox_members: { user_id: @user.id })
                                    .pluck(:id)
    end
  end
end
