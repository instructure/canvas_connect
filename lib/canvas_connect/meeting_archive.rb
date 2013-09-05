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

    extend ActiveSupport::Memoizable

    # Public: Create a new MeetingArchive.
    #
    # meeting_id - The id of the meeting on Adobe Connect (must already exist).
    # client - A CanvasConnect::Service to make requests with. (default: CanvasConnect.client)
    def initialize(meeting_id, client = CanvasConnect.client)
      @meeting_id = meeting_id
      @client = client
      @attr_cache = {}
    end

    def method_missing(meth, *args, &block)
      if ATTRIBUTES.include?(meth)
        @attr_cache[meth] ||= archive.at_xpath("//#{meth.to_s.dasherize}").try(:text)
      else
        super
      end
    end

    def archive
      @client.sco_contents(sco_id: @meeting_id, filter_icon: 'archive')
    end
    memoize :archive
    private :archive

  end
end