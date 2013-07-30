# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'
describe Event::PreconditionChecker do
  let(:course) { events(:top_course) }
  let(:person) { people(:top_leader) }

  let(:course_start_at) { course.dates.first.start_at }
  let(:preconditions) { course.kind.preconditions }

  subject { Event::PreconditionChecker.new(course, person)}
  before { preconditions.clear }

  describe "defaults" do
    its(:course_start_at) { should be_present }
    its(:course_minimum_age) { should be_blank }
    its(:valid?) { should be_true }
  end

  describe "minimum age person" do
    before { course.kind.minimum_age = 16 }

    context "has no birthday" do
      its(:valid?) { should be_false }
      its("errors_text.last") { should =~ /du bist 0 Jahre alt/ }
    end
    
    context "is younger than 16" do
      before { person.birthday = (course_start_at - 16.years - 1.day) }
      its(:valid?) { should be_false }
      its("errors_text.last") { should =~ /du bist 15 Jahre alt/ }
    end

    context "is 16 years old" do
      before { person.birthday = course_start_at - 16.years }
      its(:valid?) { should be_true }
      its("errors") { should be_empty }
    end

  end

  describe "qualification" do
    let(:sl) { qualification_kinds(:sl) }
    let(:qualifications) { person.qualifications }

    before { preconditions << sl }

    context "person without 'super lead'" do
      its(:valid?) { should be_false }
      its("errors_text.last") { should =~ /Super Lead/ }
    end

    context "person with expired 'super lead'" do
      before { qualifications << Fabricate(:qualification, qualification_kind: sl, start_at: expired_date) }
      its(:valid?) { should be_false }

      context "'super lead kind' reactivateable in range" do
        before { sl.update_attribute(:reactivateable, Date.today.year - expired_date.year) }
        its(:valid?) { should be_true }
      end
    end

    context "person with valid 'super lead'" do
      before { qualifications << Fabricate(:qualification, qualification_kind: sl, start_at: valid_date) }
      its(:valid?) { should be_true }
      its(:errors_text) { should == [] }
    end

    context "person with expired and valid 'super lead'" do
      before do
        qualifications << Fabricate(:qualification, qualification_kind: sl, start_at: expired_date)
        qualifications << Fabricate(:qualification, qualification_kind: sl, start_at: valid_date)
      end
      its(:valid?) { should be_true }
      its(:errors_text) { should == [] }
    end

    context "person with unlimited 'super lead'" do
      before do
        sl.update_attribute(:validity, nil)
        qualifications << Fabricate(:qualification, qualification_kind: sl, start_at: course_start_at - 1.day)
      end

      its(:valid?) { should be_true }
    end


    context "multiple preconditions" do
      before { preconditions << qualification_kinds(:gl) }
      its("errors_text.last") { should =~ /Qualifikationen fehlen: Super Lead, Group Lead/ }
    end

    def valid_date
      (course_start_at - sl.validity.years)
    end

    def expired_date
      (valid_date - 1.year).end_of_year
    end
  end
end

