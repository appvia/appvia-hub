# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user)
    # IMPORTANT: to understand the caveats when using blocks to specify
    # abilities see: https://github.com/CanCanCommunity/cancancan/wiki/Defining-Abilities-with-Blocks

    # https://github.com/CanCanCommunity/cancancan/wiki/Ability-Precedence explains the precedence rules

    # Hub admin role
    can :manage, :all if user.admin?

    can :read, User

    # Teams and projects

    can %i[new create], Team

    can :show, Team do |team|
      can_participate_in_team? team, user
    end

    can %i[edit update destroy], Team do |team|
      can_administer_team? team, user
    end

    # In this particular case, we have to allow certain actions for projects
    # that can't operate on a project instance (i.e. we don't have a project
    # instance to be able to check if it's allowed by the user). Thus, we expect
    # separate checks to happen at the team level instead, to authorize the user.
    can %i[new create], Project

    can %i[show edit update destroy], Project do |project|
      can_participate_in_team? project.team, user
    end
  end

  private

  def can_administer_team?(team, user)
    TeamMembershipsService.user_an_admin_of_team?(
      team.id,
      user.id
    )
  end

  def can_participate_in_team?(team, user)
    TeamMembershipsService.user_a_member_of_team?(
      team.id,
      user.id
    )
  end
end
