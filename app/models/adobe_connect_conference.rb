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

class AdobeConnectConference < WebConference

  MAX_USERNAME_LENGTH = 60

  # Public: Start a new conference and return its key. (required by WebConference)
  #
  # Returns a conference key string.
  def initiate_conference
    unless conference_key.present?
      create_meeting unless meeting_exists?
      save
    end

    find_conference_key
  end

  # Public: Determine the status of the conference (required by WebConference).
  #
  # Returns conference status as a symbol (either :active or :closed).
  def conference_status
    if meeting_exists?
      :active
    else
      :closed
    end
  end

  # Public: Add an admin to the conference and create a meeting URL (required by WebConference).
  #
  # admin - The user to add to the conference as an admin.
  # _ - Included for compatibility w/ web_conference.rb
  #
  # Returns a meeting URL string.
  def admin_join_url(admin, _ = nil)
    user = add_host(admin)

    if config[:use_sis_ids] == "no"
      settings = { :username => user.username, :password => user.password,
        :domain => CanvasConnect.config[:domain] }

      service = AdobeConnect::Service.new(settings)
      service.log_in

      "#{meeting_url}?session=#{service.session}"
    else
      meeting_url
    end
  end

  # Public: Add a participant to the conference and create a meeting URL.
  #         Make the user a conference admin if they have permissions to create
  #         a conference (required by WebConference).
  #
  # user - The user to add to the conference as an admin.
  # _ - Included for compatibility w/ web_conference.rb
  #
  # Returns a meeting URL string.
  def participant_join_url(user, _ = nil)
    if grants_right?(user, nil, :initiate)
      admin_join_url(user)
    elsif config[:use_sis_ids] == "no"
      "#{meeting_url}?guestName=#{URI.escape(user.name)}"
    else
      meeting_url
    end
  end

  # Public: List all of the recordings for a meeting
  #
  # Returns an Array of MeetingArchive, or an empty Array if there are no recordings
  def recordings
    if key = find_conference_key
      recordings = CanvasConnect::MeetingArchive.retrieve(key)
      recordings.each { |r| make_conference_public(r.id) }
      recordings.map do |recording|
        {
          recording_id: recording.id,
          duration_minutes: recording.duration.to_i,
          title: recording.name,
          updated_at: recording.date_modified,
          created_at: recording.date_created,
          playback_url: "#{config[:domain]}#{recording.url_path}",
        }
      end
    else
      []
    end
  end

  protected
  # Internal: Retrieve the SCO-ID for this meeting.
  #
  # Returns an SCO-ID string.
  def find_conference_key
    unless @conference_key.present?
      response = connect_service.sco_by_url(:url_path => meeting_url_suffix)
      if response.body.at_xpath('//status').attr('code') == 'ok'
        @conference_key = response.body.xpath('//sco[@sco-id]').attr('sco-id').value
      end
    end
    @conference_key
  end

  # Internal: Register a participant as a host.
  #
  # user - The user to add as a conference admin.
  #
  # Returns the CanvasConnect::ConnectUser.
  def add_host(user)
    options = config[:use_sis_ids] == "yes" ?
      {
        first_name: user.first_name,
        last_name:  user.last_name,
        email:      user.email,
        username:   user.sis_pseudonym_for(user.account).try(:sis_user_id),
        uuid:       user.uuid
      } :
      {
        first_name:   user.first_name,
        last_name:    user.last_name,
        email:        connect_username(user),
        username:     connect_username(user),
        uuid:         user.uuid
      }

    connect_user = AdobeConnect::User.find(options) || AdobeConnect::User.create(options)
    connect_service.permissions_update(
      :acl_id => find_conference_key,
      :principal_id => connect_user.id,
      :permission_id => 'host')

    connect_user
  end

  # Internal: Generate a Connect username that is under 60 characters
  #   (the username limit on our Connect instance).
  #
  # user - The Canvas user to generate a username for.
  #
  # Returns a username string.
  def connect_username(user)
    return @connect_username unless @connect_username.nil?

    preferred_extension = 'canvas-connect'
    current_address = user.email
    allowed_length = MAX_USERNAME_LENGTH - current_address.length
    allowed_length -= 1 unless current_address.match(/\+/)
    postfix = if allowed_length >= preferred_extension.length
      preferred_extension
    else
      user.uuid[0..allowed_length - 1]
    end

    @connect_username = if current_address.match(/\+/)
      current_address.gsub(/\+/, "+#{postfix}")
    else
      current_address.gsub(/@/, "+#{postfix}@")
    end
  end

  # Internal: Create a new Connect meeting.
  #
  # Returns nothing.
  def create_meeting
    url_id = meeting_url_suffix

    params = { :type => 'meeting',
               :name => meeting_name,
               :folder_id => meeting_folder.id,
               :date_begin => start_at.iso8601,
               :url_path => url_id }
    params[:end_at] = end_at.iso8601 if end_at.present?

    result = connect_service.sco_update(params)
    if result.body.xpath('//status[@code="ok"]').empty?
      error = result.body.at_xpath('//invalid')
      Rails.logger.error "Adobe Connect error on meeting create. Field: #{error['field']}, Value: #{error['subcode']}"

      if error['field'] == 'folder-id'
        raise CanvasConnect::MeetingFolderError.new("Folder '#{config[:meeting_container]}' doesn't exist!")
      end

      return nil
    end

    # if made it here, meeting was successfully created. Cache the meeting_url_suffix being used.
    self.meeting_url_id = url_id

    sco_id = result.body.at_xpath('//sco')['sco-id']
    make_meeting_public(sco_id)
  end

  # Internal: Make a given meeting publicly accessible.
  #
  # sco_id - The meeting's SCO-ID string.
  #
  # Returns the request object.
  def make_meeting_public(sco_id)
    connect_service.permissions_update(:acl_id => sco_id,
                                       :principal_id => 'public-access',
                                       :permission_id => 'view-hidden')
  end

  # Internal: Determine if this meeting exists in Adobe Connect.
  #
  # Returns a boolean.
  def meeting_exists?
    result = connect_service.sco_by_url(:url_path => meeting_url_id)
    result.body.xpath('//status[@code="ok"]').present?
  end

  def meeting_name
    @cached_meeting_name ||= generate_meeting_name
  end

  def meeting_url
    "#{config[:domain]}/#{meeting_url_id}"
  end

  # Internal: Get and cache a reference to the remote folder.
  #
  # Returns a CanvasConnect::MeetingFolder.
  def meeting_folder
    @meeting_folder ||= AdobeConnect::MeetingFolder.find(config[:meeting_container], CanvasConnect.client)
  end

  # Internal: Manage a connection to an Adobe Connect API.
  #
  # Returns a CanvasConnect::Service object.
  def connect_service
    CanvasConnect.client
  end

  private
  # Internal: Create a unique meeting name from the course and conference IDs.
  #
  # Returns a meeting name string.
  def generate_meeting_name
    course_code = if self.context.respond_to?(:course_code)
                    self.context.course_code
                  elsif self.context.context.respond_to?(:course_code)
                    self.context.context.course_code
                  else
                    'Canvas'
                  end

    "#{course_code}: #{self.title} [#{self.id}]"
  end

  # Internal: Get the unique ID to identify the meeting in an Adobe url.
  #
  # Returns a string or nil.
  def meeting_url_id
    # Return the stored setting value if present. If missing, return the legacy generated format.
    settings[:meeting_url_id] || meeting_url_suffix_legacy
  end

  # Internal: Track the unique ID to identify the meeting in an Adobe url.
  #
  # Returns nothing
  def meeting_url_id=(value)
    settings[:meeting_url_id] = value
  end

  # Internal: Generate a URL suffix for this conference. Uses a more globally unique approach.
  #
  # Returns a URL suffix string of format "canvas-meeting-:root_acount_global_id-:id-:created_at_as_integer".
  def meeting_url_suffix
    "canvas-mtg-#{self.context.root_account.global_id}-#{self.id}-#{self.created_at.to_i}"
  end

  # Internal: Generate a URL suffix for this conference. Uses the legacy approach with overly simple uniqueness
  #
  # Returns a URL suffix string of format "canvas-meeting-:id".
  def meeting_url_suffix_legacy
    "canvas-meeting-#{self.id}"
  end
end

