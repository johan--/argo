# frozen_string_literal: true

# notes for those who are new to CanCan:
#  * basic intro to permission checking w/ CanCan:  https://github.com/CanCanCommunity/cancancan/wiki/Checking-Abilities
#  * rules which are defined later have higher precedence, i.e. the last rule defined is the first rule applied.
#    * e.g.:
#      * if "user.is_admin?" were true, but "user.is_webauth_admin?" were false, "can? :impersonate, User" would be false
#      * the :manage_item rule would be checked using the logic for ActiveFedora::Base before falling through
#      to the Dor::AdminPolicyObject logic.
#    * more info at https://github.com/CanCanCommunity/cancancan/wiki/Ability-Precedence
#  * Argo uses this pattern for checking permissions via CanCan:  https://github.com/CanCanCommunity/cancancan/wiki/Non-RESTful-Controllers
#
# Argo specific notes:
#   * permissions granted by an APO apply to objects governed by the APO, as well as to the APO itself; hence, the fallthrough
#   check to the APO's own ID for Dor::AdminPolicyObject types in addition to the checks for ActiveFedora::Base types (e.g. the
#   "can :manage_item, Dor::AdminPolicyObject" and "can :manage_item, ActiveFedora::Base" definitions, with the latter being checked
#   first).  see https://github.com/sul-dlss/argo/issues/76
#
# note about confusing dor-services method declarations:
#  * the can_manage_*? and can_view_*? method calls (e.g. dor_item.can_manage_items? or dor_item.can_view?) don't
#  actually do anything with the state of the object that receives the message.  they could all be static methods in Dor::Governable,
#  since  they just check the intersection of the given roles with the appropriate static list of known roles.
class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new
    can :manage, :all if user.is_admin?
    cannot :impersonate, User unless user.is_webauth_admin?

    can [:manage_item, :manage_desc_metadata, :manage_governing_apo, :view_content, :view_metadata], ActiveFedora::Base if user.is_manager?
    can :create, Dor::AdminPolicyObject if user.is_manager?

    can [:view_metadata, :view_content], ActiveFedora::Base if user.is_viewer?

    can :manage_item, Dor::AdminPolicyObject do |dor_item|
      Argo::Ability.can_manage_items? user.roles(dor_item.pid)
    end

    can :manage_item, ActiveFedora::Base do |dor_item|
      if dor_item.admin_policy_object
        Argo::Ability.can_manage_items? user.roles(dor_item.admin_policy_object.pid)
      end
    end

    can :manage_desc_metadata, Dor::AdminPolicyObject do |dor_item|
      Argo::Ability.can_edit_desc_metadata? user.roles(dor_item.pid)
    end

    can :manage_desc_metadata, ActiveFedora::Base do |dor_item|
      if dor_item.admin_policy_object
        Argo::Ability.can_edit_desc_metadata? user.roles(dor_item.admin_policy_object.pid)
      end
    end

    can :manage_governing_apo, ActiveFedora::Base do |dor_item, new_apo_id|
      # user must have management privileges on both the target APO and the APO currently governing the item
      Argo::Ability.can_manage_items?(user.roles(new_apo_id)) && can?(:manage_item, dor_item)
    end

    can :view_content, Dor::AdminPolicyObject do |dor_item|
      Argo::Ability.can_view? user.roles(dor_item.pid)
    end

    can :view_metadata, Dor::AdminPolicyObject do |dor_item|
      Argo::Ability.can_view? user.roles(dor_item.pid)
    end

    can :view_content, ActiveFedora::Base do |dor_item|
      if dor_item.admin_policy_object
        Argo::Ability.can_view? user.roles(dor_item.admin_policy_object.pid)
      end
    end

    can :view_metadata, ActiveFedora::Base do |dor_item|
      if dor_item.admin_policy_object
        Argo::Ability.can_view? user.roles(dor_item.admin_policy_object.pid)
      end
    end
  end
end
