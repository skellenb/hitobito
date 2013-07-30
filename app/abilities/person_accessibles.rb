# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# This class is only used for fetching lists based on a group association.
class PersonAccessibles

  include CanCan::Ability

  attr_reader :group, :user_context

  delegate :user, :groups_group_read, :layers_read, to: :user_context

  def initialize(user, group = nil)
    @user_context = AbilityDsl::UserContext.new(user)
    @group = group

    if @group.nil?
      can :index, Person, accessible_people do |p| true end

    else # optimized queries for a given group

      # user has any role in this group
      # user has layer read of the same layer as the group
      if group_read_in_this_group? || layer_read_in_same_layer? || user.root?
        can :index, Person,
            group.people.only_public_data do |p| true end

      # user has layer read in a above layer of the group
      elsif layer_read_in_above_layer?
        can :index, Person,
            group.people.only_public_data.visible_from_above(group) do |p| true end

      elsif user.contact_data_visible?
        can :index, Person,
            group.people.only_public_data.contact_data_visible do |p| true end
      end
    end
  end

  private

  def accessible_people
    if user.root?
      Person.only_public_data
    else
      Person.only_public_data.
             joins(roles: :group).
             where(roles: {deleted_at: nil}, groups: {deleted_at: nil}).
             where(accessible_conditions.to_a).
             uniq
    end
  end

  def accessible_conditions
    condition = OrCondition.new

    if user.contact_data_visible?
      # people with contact data visible
      condition.or('people.contact_data_visible = ?', true)
    end

    if layers_read.present?
      layer_groups = read_layer_groups

      # people in same layer
      condition.or("groups.layer_group_id IN (?)", layer_groups.collect(&:id))

      # people visible from above
      visible_from_above_groups = OrCondition.new
      collapse_groups_to_highest(layer_groups) do |layer_group|
        visible_from_above_groups.or('groups.lft >= ? AND groups.rgt <= ?',
                                     layer_group.left,
                                     layer_group.rgt)
      end

      query = "(#{visible_from_above_groups.to_a.first}) AND roles.type IN (?)"
      args = visible_from_above_groups.to_a[1..-1] + [Role.visible_types.collect(&:sti_name)]
      condition.or(query, *args)
    end

    # people in group with group_read
    if groups_group_read.present?
      condition.or('groups.id IN (?)', groups_group_read)
    end

    # everybody else can access themselves
    condition.or('people.id = ?', user.id)

    condition
  end

  # If group B is a child of group A, B is collapsed into A.
  # e.g. input [A,B] -> output A
  def collapse_groups_to_highest(layer_groups)
    layer_groups.each do |group|
      unless layer_groups.any? {|g| g.is_ancestor_of?(group) }
        yield group
      end
    end
  end

  def group_read_in_this_group?
    groups_group_read.include?(group.id)
  end

  def layer_read_in_same_layer?
    layers_read.present? && layers_read.include?(group.layer_group_id)
  end

  def layer_read_in_above_layer?
    layers_read.present? && (layers_read & group.layer_hierarchy.collect(&:id)).present?
  end

  def read_layer_groups
    (user.groups_with_permission(:layer_full) + user.groups_with_permission(:layer_read)).collect(&:layer_group).uniq
  end

end
