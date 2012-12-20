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

require File.expand_path(File.dirname(__FILE__) + '/../../../../../../spec/spec_helper')

describe CanvasConnect::Service do
  subject { CanvasConnect::Service.new('username', 'password', 'http://connect.example.com') }

  before(:each) do
    subject.stubs(:session_key).returns('CookieValue')
  end

  let(:login_response) do
    body = <<-END
      <?xml version="1.0" encoding="utf-8"?>
      <results>
        <status code="ok" />
      </results>
    END

    CanvasConnect::Response.new(200, {}, body)
  end

  let(:session_response) do
    body = <<-END
      <?xml version="1.0" encoding="utf-8"?>
      <results>
        <status code="ok" />
        <common locale="en" time-zone-id="1" time-zone-java-id="America/Denver">
          <cookie>CookieValue</cookie>
          <date>2012-12-21T12:00:00Z</date>
          <host>http://connect.example.com</host>
          <local-host>SpecHost</local-host>
          <admin-host>http://connect.example.com</admin-host>
          <url>/api/xml?action=common-info&session=CookieValue</url>
          <version>9.0.0.1</version>
          <account account-id="1" />
          <user user-id="1" type="user">
            <name>Don Draper</name>
            <login>don@sterlingcooperdraperpryce.com</login>
          </user>
        </common>
        <reg-user>
          <is-reg-user>false</is-reg-user>
        </reg-user>
      </results>
    END

    CanvasConnect::Response.new(200, {}, body)
  end

  it { should respond_to(:username) }
  it { should respond_to(:domain) }
  it { should respond_to(:is_authenticated) }

  describe 'initialize' do
    it 'should require a username' do
      lambda { CanvasConnect::Service.new }.should raise_error(ArgumentError)
    end

    it 'should require a password' do
      lambda { CanvasConnect::Service.new('username') }.should raise_error(ArgumentError)
    end

    it 'should require a domain' do
      lambda { CanvasConnect::Service.new('username', 'password') }.should raise_error(ArgumentError)
    end
  end

  describe 'log in' do
    it 'should authenticate the given user' do
      subject.expects(:request).with('login', { :login => 'username', :password => 'password' }, true).returns(login_response)
      subject.log_in
      subject.should be_logged_in
    end
  end

  describe 'method_missing' do
    before(:each) do
      Struct.new('FakeResponse', :status, :headers, :body)
      @fake_response = Struct::FakeResponse.new(200, {}, '')
    end

    it 'should pass unknown methods onto the Adobe Connect API' do
      subject.send(:client).expects(:get).with('http://connect.example.com/api/xml?action=fake-call', {'session' => 'CookieValue'}).returns(@fake_response)
      subject.fake_call.should be_an_instance_of(CanvasConnect::Response)
    end
  end
end
