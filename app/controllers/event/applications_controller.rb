# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Event::ApplicationsController < ApplicationController
  
  before_filter :application
  authorize_resource
      
  def approve
    toggle_approval(true, 'freigegeben')
  end
  
  def reject
    toggle_approval(false, 'abgelehnt')
  end
  
  private
  
  def toggle_approval(approved, verb)
    application.approved = approved
    application.rejected = !approved
    application.save!
    flash[:notice] = "Die Anmeldung wurde #{verb}"
    redirect_to group_event_participation_path(group, participation.event_id, participation)
  end
  
  def application
    @application ||= Event::Application.find(params[:id])
  end
  
  def group
    @group ||= Group.find(params[:group_id])
  end
  
  def participation
    application.participation
  end
end