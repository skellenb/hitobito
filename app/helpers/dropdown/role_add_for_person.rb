# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Dropdown
  class RoleAddForPerson < RoleAdd
    attr_reader :person

    def initialize(template, group, person)
      # must be set BEFORE initialize, so we have it when building items
      @person = person

      super(template, GroupDecorator.new(group))

      # must be set AFTER initializer, so we override what intialize defined for us
      @label = 'Rolle hinzufügen'
      @button_class = 'btn btn-small'
    end

    private

    def link(entry)
      template.new_group_role_path(group,
                                   role: { type: entry[:sti_name], person_id: person.id },
                                   return_url: template.group_person_path(group.id, person.id))
    end

  end
end
