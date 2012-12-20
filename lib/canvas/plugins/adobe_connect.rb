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

module Canvas
  module Plugins
    class AdobeConnect
      # Public: Bootstrap the gem on app load.
      #
      # Returns nothing.
      def initialize; register; end

      protected
      # Internal: Register as a plugin with Canvas.
      #
      # Returns a Canvas plugin object.
      def register
        Canvas::Plugin.register('adobe_connect', :web_conferencing, {
          :name => lambda { t(:name, 'Adobe Connect') },
          :description => lambda { t(:description, 'Adobe Connect web conferencing support.') },
          :author => 'OCAD University',
          :author_website => 'http://www.ocadu.ca',
          :version => CanvasConnect::VERSION,
          :settings_partial => 'plugins/connect_settings',
          :validator => 'AdobeConnectValidator',
          :encrypted_settings => [:password] })
      end
    end
  end
end
