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

describe CanvasConnect::Response do
  let(:body) { '<?xml version="1.0"?><items><item>Item Name</item></items>' }
  subject { CanvasConnect::Response.new(200, {}, body) }

  it { should respond_to(:status) }
  it { should respond_to(:headers) }
  it { should respond_to(:body) }

  its(:body) { should be_an_instance_of(Nokogiri::XML::Document) }

  describe 'initialize' do
    it 'should require a status' do
      lambda { CanvasConnect::Response.new }.should raise_error(ArgumentError)
    end

    it 'should require headers' do
      lambda { CanvasConnect::Response.new(200) }.should raise_error(ArgumentError)
    end

    it 'should require a body' do
      lambda { CanvasConnect::Response.new(200, {}) }.should raise_error(ArgumentError)
    end
  end

  describe 'simple delegator' do
    let(:body) { '<?xml version="1.0"?><items><item>Item Name</item></items>' }

    it 'should delegate to body' do
      subject.xpath('//item').text.should eql 'Item Name'
    end
  end
end
