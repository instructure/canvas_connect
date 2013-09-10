#
# Copyright (C) 2013 Instructure, Inc.
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
module CanvasConnect
  class MeetingArchive
    ATTRIBUTES = [:name, :url_path, :date_begin, :date_end, :date_modified, :duration, :date_created]
    attr_accessor :meeting_id

    def self.retrieve(meeting_id, client = CanvasConnect.client)
      result = client.sco_contents(sco_id: meeting_id, filter_icon: 'archive')
      Array(result.at_xpath('results/scos').try(:children)).map do |archive|
        MeetingArchive.new(Nokogiri::XML(archive.to_xml))
      end
    end

    # Public: Create a new MeetingArchive.
    #
    # meeting_id - The id of the meeting on Adobe Connect (must already exist).
    # client - A CanvasConnect::Service to make requests with. (default: CanvasConnect.client)
    def initialize(archive)
      @attr_cache = {}
      @archive = archive
    end

    def id
      @archive.attr('sco-id')
    end

    def method_missing(meth, *args, &block)
      if ATTRIBUTES.include?(meth)
        @attr_cache[meth] ||= @archive.at_xpath("//#{meth.to_s.dasherize}").try(:text)
      else
        super
      end
    end

  end
end