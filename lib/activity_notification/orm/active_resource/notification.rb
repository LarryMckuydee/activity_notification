require 'activity_notification/apis/notification_api'

module ActivityNotification
  module ORM
    module ActiveResource
      class Notification < ActiveResource::Base
        include Common
        include Renderable
        include NotificationApi

        self.table_name = ActivityNotification.config.table_name || ActivityNotification.config.notification_table_name

        belongs_to :target

        # Belongs to notifiable instance of this notification as polymorphic association.
        # @scope instance
        # @return [Object] Notifiable instance of this notification
        belongs_to :notifiable

        # Belongs to group instance of this notification as polymorphic association.
        # @scope instance
        # @return [Object] Group instance of this notification
        belongs_to :group

        # Belongs to group owner notification instance of this notification.
        # Only group member instance has :group_owner value.
        # Group owner instance has nil as :group_owner association.
        # @scope instance
        # @return [Notification] Group owner notification instance of this notification
        belongs_to :group_owner, { class_name: "ActivityNotification::Notification" }.merge(Rails::VERSION::MAJOR >= 5 ? { optional: true } : {})

        # Has many group member notification instances of this notification.
        # Only group owner instance has :group_members value.
        # Group member instance has nil as :group_members association.
        # @scope instance
        # @return [ActiveRecord_AssociationRelation<Notificaion>] Database query of the group member notification instances of this notification
        has_many   :group_members, class_name: "ActivityNotification::Notification", foreign_key: :group_owner_id

        # Belongs to :otifier instance of this notification.
        # @scope instance
        # @return [Object] Notifier instance of this notification
        belongs_to :notifier

        # Serialize parameters Hash
        serialize  :parameters, Hash

        validates  :target,        presence: true
        validates  :notifiable,    presence: true
        validates  :key,           presence: true

        # Selects group owner notifications only.
        # @scope class
        # @return [ActiveRecord_AssociationRelation<Notificaion>] Database query of filtered notifications
        scope :group_owners_only,                 -> { where(group_owner_id: nil) }

        # Selects group member notifications only.
        # @scope class
        # @return [ActiveRecord_AssociationRelation<Notificaion>] Database query of filtered notifications
        scope :group_members_only,                -> { where.not(group_owner_id: nil) }

        # Selects unopened notifications only.
        # @scope class
        # @return [ActiveRecord_AssociationRelation<Notificaion>] Database query of filtered notifications
        scope :unopened_only,                     -> { where(opened_at: nil) }

        # Selects opened notifications only without limit.
        # Be careful to get too many records with this method.
        # @scope class
        # @return [ActiveRecord_AssociationRelation<Notificaion>] Database query of filtered notifications
        scope :opened_only!,                      -> { where.not(opened_at: nil) }

        # Selects opened notifications only with limit.
        # @scope class
        # @param [Integer] limit Limit to query for opened notifications
        # @return [ActiveRecord_AssociationRelation<Notificaion>] Database query of filtered notifications
        scope :opened_only,                       ->(limit) { opened_only!.limit(limit) }

        # Selects group member notifications in unopened_index.
        # @scope class
        # @return [ActiveRecord_AssociationRelation<Notificaion>] Database query of filtered notifications
        scope :unopened_index_group_members_only, -> { where(group_owner_id: unopened_index.map(&:id)) }

        # Selects group member notifications in opened_index.
        # @scope class
        # @param [Integer] limit Limit to query for opened notifications
        # @return [ActiveRecord_AssociationRelation<Notificaion>] Database query of filtered notifications
        scope :opened_index_group_members_only,   ->(limit) { where(group_owner_id: opened_index(limit).map(&:id)) }

        # Selects notifications within expiration.
        # @scope class
        # @param [ActiveSupport::Duration] expiry_delay Expiry period of notifications
        # @return [ActiveRecord_AssociationRelation<Notificaion>] Database query of filtered notifications
        scope :within_expiration_only,            ->(expiry_delay) { where("created_at > ?", expiry_delay.ago) }

        # Selects group member notifications with specified group owner ids.
        # @scope class
        # @param [Array<String>] owner_ids Array of group owner ids
        # @return [ActiveRecord_AssociationRelation<Notificaion>] Database query of filtered notifications
        scope :group_members_of_owner_ids_only,   ->(owner_ids) { where(group_owner_id: owner_ids) }

        # Selects filtered notifications by target instance.
        #   ActivityNotification::Notification.filtered_by_target(@user)
        # is the same as
        #   @user.notifications
        # @scope class
        # @param [Object] target Target instance for filter
        # @return [ActiveRecord_AssociationRelation<Notificaion>] Database query of filtered notifications
        scope :filtered_by_target,                ->(target) { where(target: target) }

        # Selects filtered notifications by notifiable instance.
        # @example Get filtered unopened notificatons of the @user for @comment as notifiable
        #   @notifications = @user.notifications.unopened_only.filtered_by_instance(@comment)
        # @scope class
        # @param [Object] notifiable Notifiable instance for filter
        # @return [ActiveRecord_AssociationRelation<Notificaion>] Database query of filtered notifications
        scope :filtered_by_instance,              ->(notifiable) { where(notifiable: notifiable) }

        # Selects filtered notifications by notifiable_type.
        # @example Get filtered unopened notificatons of the @user for Comment notifiable class
        #   @notifications = @user.notifications.unopened_only.filtered_by_type('Comment')
        # @scope class
        # @param [String] notifiable_type Notifiable type for filter
        # @return [ActiveRecord_AssociationRelation<Notificaion>] Database query of filtered notifications
        scope :filtered_by_type,                  ->(notifiable_type) { where(notifiable_type: notifiable_type) }

        # Selects filtered notifications by group instance.
        # @example Get filtered unopened notificatons of the @user for @article as group
        #   @notifications = @user.notifications.unopened_only.filtered_by_group(@article)
        # @scope class
        # @param [Object] group Group instance for filter
        # @return [ActiveRecord_AssociationRelation<Notificaion>] Database query of filtered notifications
        scope :filtered_by_group,                 ->(group) { where(group: group) }

        # Includes target instance with query for notifications.
        # @return [ActiveRecord_AssociationRelation<Notificaion>] Database query of notifications with target
        scope :with_target,                       -> { includes(:target) }

        # Includes notifiable instance with query for notifications.
        # @return [ActiveRecord_AssociationRelation<Notificaion>] Database query of notifications with notifiable
        scope :with_notifiable,                   -> { includes(:notifiable) }

        # Includes group instance with query for notifications.
        # @return [ActiveRecord_AssociationRelation<Notificaion>] Database query of notifications with group
        scope :with_group,                        -> { includes(:group) }

        # Includes group owner instances with query for notifications.
        # @return [ActiveRecord_AssociationRelation<Notificaion>] Database query of notifications with group owner
        scope :with_group_owner,                  -> { includes(:group_owner) }

        # Includes group member instances with query for notifications.
        # @return [ActiveRecord_AssociationRelation<Notificaion>] Database query of notifications with group members
        scope :with_group_members,                -> { includes(:group_members) }

        # Includes notifier instance with query for notifications.
        # @return [ActiveRecord_AssociationRelation<Notificaion>] Database query of notifications with notifier
        scope :with_notifier,                     -> { includes(:notifier) }

        # Returns latest notification instance.
        # @return [Notification] Latest notification instance
        def self.latest
          latest_order.first
        end

        # Returns earliest notification instance.
        # @return [Notification] Earliest notification instance
        def self.earliest
          earliest_order.first
        end

        # Selects unique keys from query for notifications.
        # @return [Array<String>] Array of notification unique keys
        def self.uniq_keys
          # select method cannot be chained with order by other columns like created_at
          # select(:key).distinct.pluck(:key)
          pluck(:key).uniq
        end

        # Raise DeleteRestrictionError for notifications.
        def self.raise_delete_restriction_error(error_text)
          raise ::ActiveRecord::DeleteRestrictionError.new(error_text)
        end

        protected

          # Returns count of group members of the unopened notification.
          # This method is designed to cache group by query result to avoid N+1 call.
          # @api protected
          #
          # @return [Integer] Count of group members of the unopened notification
          def unopened_group_member_count
            # Cache group by query result to avoid N+1 call
            unopened_group_member_counts = target.notifications
                                                 .unopened_index_group_members_only
                                                 .group(:group_owner_id)
                                                 .count
            unopened_group_member_counts[id] || 0
          end

          # Returns count of group members of the opened notification.
          # This method is designed to cache group by query result to avoid N+1 call.
          # @api protected
          #
          # @param [Integer] limit Limit to query for opened notifications
          # @return [Integer] Count of group members of the opened notification
          def opened_group_member_count(limit = ActivityNotification.config.opened_index_limit)
            # Cache group by query result to avoid N+1 call
            opened_group_member_counts   = target.notifications
                                                 .opened_index_group_members_only(limit)
                                                 .group(:group_owner_id)
                                                 .count
            count = opened_group_member_counts[id] || 0
            count > limit ? limit : count
          end

          # Returns count of group member notifiers of the unopened notification not including group owner notifier.
          # This method is designed to cache group by query result to avoid N+1 call.
          # @api protected
          #
          # @return [Integer] Count of group member notifiers of the unopened notification
          def unopened_group_member_notifier_count
            # Cache group by query result to avoid N+1 call
            unopened_group_member_notifier_counts = target.notifications
                                                          .unopened_index_group_members_only
                                                          .includes(:group_owner)
                                                          .where('group_owners_notifications.notifier_type = notifications.notifier_type')
                                                          .where.not('group_owners_notifications.notifier_id = notifications.notifier_id')
                                                          .references(:group_owner)
                                                          .group(:group_owner_id, :notifier_type)
                                                          .count('distinct notifications.notifier_id')
            unopened_group_member_notifier_counts[[id, notifier_type]] || 0
          end

          # Returns count of group member notifiers of the opened notification not including group owner notifier.
          # This method is designed to cache group by query result to avoid N+1 call.
          # @api protected
          #
          # @param [Integer] limit Limit to query for opened notifications
          # @return [Integer] Count of group member notifiers of the opened notification
          def opened_group_member_notifier_count(limit = ActivityNotification.config.opened_index_limit)
            # Cache group by query result to avoid N+1 call
            opened_group_member_notifier_counts   = target.notifications
                                                          .opened_index_group_members_only(limit)
                                                          .includes(:group_owner)
                                                          .where('group_owners_notifications.notifier_type = notifications.notifier_type')
                                                          .where.not('group_owners_notifications.notifier_id = notifications.notifier_id')
                                                          .references(:group_owner)
                                                          .group(:group_owner_id, :notifier_type)
                                                          .count('distinct notifications.notifier_id')
            count = opened_group_member_notifier_counts[[id, notifier_type]] || 0
            count > limit ? limit : count
          end
      end
    end
  end
end
