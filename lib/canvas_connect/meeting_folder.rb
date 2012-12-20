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

module CanvasConnect
  class MeetingFolder
    attr_accessor :name

    extend ActiveSupport::Memoizable

    # Public: Create a new MeetingFolder.
    #
    # name - The name of the folder on Adobe Connect (must already exist).
    # client - A CanvasConnect::Service to make requests with. (default: CanvasConnect.client)
    def initialize(name, client = CanvasConnect.client)
      @name   = name
      @client = client
    end

    # Public: Get the SCO ID for this folder.
    #
    # Returns an SCO ID string or nil if it doesn't exist.
    def id
      container     = @client.sco_shortcuts.at_xpath('//sco[@type="user-meetings"]')
      remote_folder = @client.sco_expanded_contents(:sco_id => container['sco-id'],
                                                   :filter_name => @name)

      remote_folder.at_xpath('//sco')['sco-id']
    rescue NoMethodError
      # Return nil if the container or remote_folder can't be found.
      nil
    end
    memoize :id

    # Public: Get the URL path for this folder.
    #
    # Returns a URL fragment string or nil if it can't be queried.
    def url_path
      response = @client.sco_info(:sco_id => @id)
      response.at_xpath('//url-path').text
    rescue NoMethodError
      nil
    end
    memoize :url_path
  end
end
