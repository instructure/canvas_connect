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

require "adobe_connect"

module CanvasConnect
  class ConnectionError < StandardError; end
  class MeetingFolderError < StandardError; end
  class MeetingNotFound < StandardError; end

  class Engine < Rails::Engine
    config.paths['lib'].eager_load!

    config.to_prepare do
      Canvas::Plugins::AdobeConnect.new
    end
  end

  # Public: Find the plugin configuration.
  #
  # Returns a settings hash.
  def self.config
    settings = Canvas::Plugin.find('adobe_connect').settings || {}
    AdobeConnect::Config.declare do
      username settings[:login]
      password settings[:password_dec]
      domain   settings[:domain]
    end
    settings
  end

  # Return a cached Connect Service object to make requests with.
  #
  # Returns a AdobeConnect::Service.
  def self.client
    @clients ||= {}
    settings = self.config
    client = @clients[settings]

    unless client
      connect_settings = {
        :username => settings[:login],
        :password => settings[:password_dec],
        :domain   => settings[:domain]
      }
      client = AdobeConnect::Service.new(connect_settings)
      client.log_in
      @clients[settings] = client
    end

    client
  end
end
