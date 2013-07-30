# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Export::CsvPeople::ParticipationsAddress do
  
  let(:person) { people(:top_leader) }
  let(:participation) { Fabricate(:event_participation, person: person, event: events(:top_course)) }
  let(:list) { [participation] }
  let(:people_list) { Export::CsvPeople::ParticipationsAddress.new(list) }

  subject { people_list }

  context "address data" do
    its([:first_name]) { should eq 'Vorname' }
    its([:town]) { should eq 'Ort' }
  end
end
