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
    module Validators
      module AdobeConnectValidator
        # Public: An array of allowed plugin settings.
        REQUIRED_KEYS = %w{domain login password meeting_container}

        # Public: Validate setting input for this plugin.
        #
        # settings - A hash of settings params.
        # plugin_setting - A plugin setting object.
        #
        # Returns false on error or a hash of settings options.
        def self.validate(settings, plugin_setting)
          filtered_settings = settings.slice(*REQUIRED_KEYS)
          if all_empty?(filtered_settings)
            # Allow no settings.
            {}
          else
            if valid?(filtered_settings)
              filtered_settings
            else
              plugin_setting.errors.add_to_base(I18n.t('canvas.plugins.errors.all_fields_required', 'All fields are required'))
              false
            end
          end
        end

        protected
        # Internal: Determine if a given settings hash is empty.
        #
        # settings - A hash of setting params.
        #
        # Returns a boolean.
        def self.all_empty?(settings)
          settings.values.all?(&:blank?)
        end

        # Internal: Determine if any settings are missing from the given hash.
        #
        # settings - A hash of setting params.
        #
        # Returns a boolean.
        def self.any_empty?(settings)
          settings.values.any?(&:blank?)
        end

        # Internal: Validate that all required settings are present.
        #
        # settings - The hash of settings to validate.
        #
        # Returns boolean.
        def self.valid?(settings)
          !(any_empty?(settings) || (REQUIRED_KEYS & settings.keys) != REQUIRED_KEYS)
        end
      end
    end
  end
end

