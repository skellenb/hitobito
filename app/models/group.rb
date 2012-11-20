# == Schema Information
#
# Table name: groups
#
#  id                  :integer          not null, primary key
#  parent_id           :integer
#  lft                 :integer
#  rgt                 :integer
#  name                :string(255)      not null
#  short_name          :string(31)
#  type                :string(255)      not null
#  email               :string(255)
#  address             :string(1024)
#  zip_code            :integer
#  town                :string(255)
#  country             :string(255)
#  contact_id          :integer
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  deleted_at          :datetime
#  layer_group_id      :integer
#  bank_account        :string(255)
#  jubla_insurance     :boolean          default(FALSE), not null
#  jubla_full_coverage :boolean          default(FALSE), not null
#  parish              :string(255)
#  kind                :string(255)
#  unsexed             :boolean          default(FALSE), not null
#  clairongarde        :boolean          default(FALSE), not null
#  founding_year       :integer
#

class Group < ActiveRecord::Base
  
  MINIMAL_SELECT = %w(id name type parent_id lft rgt layer_group_id deleted_at).collect {|a| "groups.#{a}"}
  
  
  include Group::Types
  include Contactable
  
  ### ATTRIBUTES
  
  class_attribute :event_types
  # All possible Event types that may be created for this group
  self.event_types = [Event]
  
  attr_accessible :name, :short_name, :email, :contact_id

  attr_readonly :type


  ### CALLBACKS
  
  after_create :set_layer_group_id
  after_create :create_default_children
  after_destroy :destroy_orphaned_events
  
  # Root group may not be destroyed
  protect_if :root?
  
  
  ### ASSOCIATIONS
  
  acts_as_nested_set dependent: :destroy
  acts_as_paranoid
  
  belongs_to :contact, class_name: 'Person'
  
  has_many :roles, dependent: :destroy, inverse_of: :group
  has_many :people, through: :roles
  
  has_many :people_filters, dependent: :destroy
  
  has_and_belongs_to_many :events, after_remove: :destroy_orphaned_event
  
  
  ### VALIDATIONS
  
  validate :assert_type_is_allowed_for_parent, on: :create
  
  
  ### INDEX
  
  define_partial_index do
    indexes name, short_name, sortable: true
    indexes email, address, zip_code, town, country

    indexes phone_numbers.number, as: :phone_number
    indexes social_accounts.name, as: :social_account
  end
  
  
  ### CLASS METHODS
  
  class << self
    
    # Is the given attribute used in the current STI class
    def attr_used?(attr)
      [:default, :superior].any? do |role|
        accessible_attributes(role).include?(attr)
      end
    end

    def superior_attributes
      accessible_attributes(:superior).to_a - accessible_attributes(:default).to_a
    end

    # order groups by type. If a parent group is given, order the types
    # as they appear in possible_children, otherwise order them 
    # hierarchically over all group types.
    def order_by_type(parent_group = nil)
      types = parent_group ? parent_group.possible_children : Group.all_types
      if types.present?
        statement = "CASE groups.type "
        types.each_with_index do |t, i|
          statement << "WHEN '#{t.sti_name}' THEN #{i} "
        end
        statement << "END, "
      end
      reorder("#{statement} name") # acts_as_nested_set default to new order
    end

    def can_offer_courses
      sti_names = all_types.select { |group| group.event_types.include?(Event::Course) }.map(&:sti_name)
      scoped.where(type: sti_names).order(:parent_id, :name)
    end
  end
  
  
  ### INSTANCE METHODS
  
  
  # The hierarchy from top to bottom of and including this group.
  def hierarchy
    @hierarchy ||= self_and_ancestors.select(MINIMAL_SELECT)
  end
  
  # The layer of this group.
  def layer_group
    layer ? self : layer_groups.last
  end
  
  # The layer hierarchy from top to bottom of this group.
  def layer_groups
    hierarchy.select { |g| g.class.layer }
  end
  
  def groups_in_same_layer
    Group.where(layer_group_id: layer_group_id)
  end
  
  # The layer hierarchy without the layer of this group.
  def upper_layer_groups
    if new_record?
      if parent
        if layer?
          parent.layer_groups
        else
          parent.layer_groups - [parent.layer_group]
        end
      else
        []
      end
    else
      layer_groups - [layer_group]
    end
  end
  
  def to_s
    name
  end
  
  def new_event
    event = events.new
    event.groups << self
    event
  end
  
  private
  
  def assert_type_is_allowed_for_parent
    if type && parent && !parent.possible_children.collect(&:sti_name).include?(type)
      errors.add(:type, :type_not_allowed) 
    end 
  end

  def set_layer_group_id
    layer_group_id = self.class.layer ? id : parent.layer_group_id
    update_column(:layer_group_id, layer_group_id)
  end
  
  def create_default_children
    default_children.each do |group_type|
      child = group_type.new(name: group_type.model_name.human)
      child.parent = self
      child.save!
    end
  end
  
  def destroy_orphaned_events
    events.includes(:groups).each do |e|
      destroy_orphaned_event(e)
    end
  end
  
  def destroy_orphaned_event(event)
    if event.group_ids.blank? || event.group_ids == [id]
      event.destroy
    end
  end

end
