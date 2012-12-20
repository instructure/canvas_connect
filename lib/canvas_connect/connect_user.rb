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
  class ConnectUser
    attr_accessor :id, :canvas_user
    attr_reader :client

    # Public: Create a new ConnectUser instance.
    #
    # canvas_user - A Canvas User object.
    # client - A CanvasConnect::Service instance. (default: CanvasConnect.client)
    def initialize(canvas_user, client = CanvasConnect.client)
      @canvas_user, @client = [canvas_user, client]
    end

    # Public: Save this user to the Adobe Connect instance.
    #
    # Returns true.
    def save
      response = @client.principal_update(
        :first_name => @canvas_user.first_name,
        :last_name => @canvas_user.last_name,
        :login => username,
        :password => password,
        :type => 'user',
        :has_children => 0,
        :email => @canvas_user.email)
      @id = response.at_xpath('//principal')['principal-id']
      true
    end

    # Public: Generate a unique Adobe Connect username for this user.
    #
    # Examples
    #
    #   connect_user.username #=> canvas_user_15
    #
    # Returns a username string.
    def username
      "canvas_user_#{@canvas_user.id}"
    end

    # Internal: Generate a 10 character password for Adobe Connect.
    #
    # Returns a password string.
    def password
      @password ||= Digest::SHA1.hexdigest(@canvas_user.uuid)[0..9]
    end

    class << self
      # Public: Find a Canvas user on an Adobe Connect instance.
      #
      # user - A Canvas user object.
      #
      # Returns a CanvasConnect::ConnectUser or nil.
      def find(user)
        connect_user = ConnectUser.new(user)
        response = connect_user.client.principal_list(:filter_login => connect_user.username)
        if found_user = response.at_xpath('//principal')
          connect_user.id = found_user['principal-id']
          connect_user
        else
          nil
        end
      end

      # Public: Create an Adobe Connect user for the given Canvas user.
      #
      # user - The Canvas user to create in Connect.
      #
      # Returns a new CanvasConnect::ConnectUser.
      def create(user)
        new_user = ConnectUser.new(user)
        new_user.save

        new_user
      end

      # Public: Find the given user in Connect or, if they don't exist, create them.
      #
      # user - A Canvas user.
      #
      # Returns a CanvasConnect::ConnectUser.
      def find_or_create(user)
        find(user) || create(user)
      end
    end
  end
end
