# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe "event/participations/_actions_index.html.haml" do

  #subject { render; Capybara::Node::Simple.new(rendered).all('a').last }
  let(:event) { EventDecorator.decorate(Fabricate(:course, groups: [groups(:top_layer)])) }
  let(:participation) { Fabricate(:event_participation, event: event) }
  let(:leader) { Fabricate(Event::Role::Leader.name.to_sym, participation: participation) }
  
  let(:dom) { render; Capybara::Node::Simple.new(@rendered) }
  let(:dropdowns) { dom.all('.dropdown-toggle') }

  let(:params) { {"action"=>"index",
                  "controller"=>"event/participations",
                  "group_id"=>"1",
                  "event_id"=>"36"} }

  before do
    assign(:event, event)
    assign(:group, event.groups.first)
    view.stub(parent: event)
    view.stub(entries: [participation])
    view.stub(params: params)
  end

  it "top leader has dropdowns for adding and exporting" do
    login_as(people(:top_leader))
    
    dropdowns[0].should have_content('Person hinzufügen')
    dropdowns[1].should have_content('Export')
  end
  
  it "event leader has dropdowns for adding and exporting" do
    login_as(leader.participation.person)
    
    dropdowns[0].should have_content('Person hinzufügen')
    dropdowns[1].should have_content('Export')
  end
  
  def login_as(user)
    controller.stub(current_user: user)
    view.stub(current_user: user)
  end
end
