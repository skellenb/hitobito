# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe "event/participations/_actions_show.html.haml" do
  let(:participant) { people(:top_leader )}
  let(:participation) { Fabricate(:event_participation, person: participant) }
  let(:user) { participant }
  let(:event) { participation.event }
  let(:group) { event.groups.first}

  before do 
    view.stub(path_args: [group, event])
    view.stub(entry: participation) 
    controller.stub(current_user: user)
    view.stub(:current_user) {user}
    controller.request.path_parameters[:action] = 'show'
    controller.request.path_parameters[:group_id] = 42
    controller.request.path_parameters[:event_id] = 42
    controller.request.path_parameters[:id] = 42
    assign(:event, event)
    assign(:group, group)
  end
  

  context "last button" do
    subject { Capybara::Node::Simple.new(rendered).all('a').last }
  
    context "last button per default is the change contact data button" do
      before { render }
    
      its([:href]) { should eq edit_group_person_path(user.groups.first, user, return_url: '/groups/42/events/42/participations/42') }
      its(:text) { should eq " Kontaktdaten ändern" } # space because of icon
    end
  end
  
end
