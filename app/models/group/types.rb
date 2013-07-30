# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Group::Types
  extend ActiveSupport::Concern
  
  
  included do
    class_attribute :layer, :role_types, :possible_children, :default_children
    
    # Whether this group type builds a layer or is a regular group. Layers influence some permissions.
    self.layer = false
    # List of the role types that are available for this group type.
    self.role_types = []
    # Child group types that may be created for this group type.
    self.possible_children = []
    # Child groups that are automatically created with a group of this type.
    self.default_children = []
  end
  
  module ClassMethods
    # DSL method to define children
    def children(*group_types)
      self.possible_children = group_types + self.possible_children
    end
    
    # DSL method to define roles
    def roles(*types)
      self.role_types = types + self.role_types
    end
    
    # All group types available in the application
    def all_types
      @@all_types ||= collect_types([], root_types)
    end
    
    # All root group types in the application.
    # Used as a DSL method to define root types if arguments are given.
    def root_types(*types)
      @@root_types ||= []
      if types.present?
        reset_types!
        @@root_types += types
      else
        @@root_types.clone
      end
    end
    
    # Helper method to clear the cached group and role types.
    def reset_types!
      @@root_types = []
      @@all_types = nil
      Role.reset_types!
    end
    
    # All the group types underneath the current group type.
    def child_types
      collect_types([], [self])
    end
    
    # Return the group type with the given sti_name or raise an exception if not found
    def find_group_type!(sti_name)
      type = all_types.detect { |t| t.sti_name == sti_name }
      raise ActiveRecord::RecordNotFound, "No group '#{sti_name}' found" if type.nil?
      type
    end
    
    # Return the role type with the given sti_name or raise an exception if not found
    def find_role_type!(sti_name)
      type = role_types.detect { |t| t.sti_name == sti_name }
      raise ActiveRecord::RecordNotFound, "No role '#{sti_name}' found" if type.nil?
      type
    end
    
    def label
      model_name.human
    end
    
    def label_plural
      model_name.human(count: 2)
    end
    
    private
    
    def collect_types(all, types)
      types.each do |type|
        # if a type appears more than once, put it at the end of the list
        previous = all.delete(type)
        all << type
        collect_types(all, type.possible_children) if previous.nil?
      end
      all
    end
    
  end
end
