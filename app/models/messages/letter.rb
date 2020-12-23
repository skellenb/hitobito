# frozen_string_literal: true

#  Copyright (c) 2020, CVP Schweiz. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_cvp.

class Messages::Letter < Message

  has_rich_text :content

  before_save :set_message_recipients

  def to_s
    subject
  end

  private

  def target(person)
    address(person)
  end

  def address(contactable)
    parts = []
    parts << contactable.company_name if contactable.try(:company) && contactable.company_name?
    parts << contactable.nickname if contactable.respond_to?(:nickname) && contactable.nickname.present?
    parts << contactable.address.to_s if contactable.address.to_s.strip.present?
    parts << "#{contactable.zip_code.to_s} #{contactable.town.to_s}"
    parts << contactable.country_label unless contactable.ignored_country?
    parts.join("\n")
  end

end
