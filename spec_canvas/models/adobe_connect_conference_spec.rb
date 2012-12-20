#
# Copyright (C) 2012 Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.
#

require File.expand_path(File.dirname(__FILE__) + '/../../../../../spec/spec_helper')

describe AdobeConnectConference do
  CONNECT_CONFIG = {
    :domain => 'http://connect.example.com',
    :username => 'user',
    :password => 'password',
    :password_dec => 'password',
    :meeting_container => 'canvas_meetings'
  }

  before(:each) do
    AdobeConnectConference.stubs(:config).returns(CONNECT_CONFIG)
    @conference = AdobeConnectConference.new
  end

  subject { AdobeConnectConference.new }

  context 'with an admin participant' do
    before(:each) do
      @user = User.new(:name => 'Don Draper')
    end

    it 'should generate an admin url' do
      CanvasConnect::Service.stubs(:user_session).returns('CookieValue')
      @conference.expects(:add_host).with(@user).returns(@user)
      @conference.admin_join_url(@user).should == "http://connect.example.com/canvas-meeting-#{@conference.id}"
    end
  end
end
