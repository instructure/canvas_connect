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
    if meeting_exists? && end_at.present? && Time.now < end_at
      :active
    elsif meeting_exists?
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
    settings = { :username => user.username, :password => user.password,
      :domain => CanvasConnect.config[:domain] }

    Rails.logger.info "USERNAME: #{user.username}"
    Rails.logger.info "PASSWORD: #{user.password}"

    service = AdobeConnect::Service.new(settings)
    service.log_in

    "#{meeting_url}?session=#{service.session}"
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
    else
      "#{meeting_url}?guestName=#{URI.escape(user.name)}"
    end
  end

  protected
  # Internal: Retrieve the SCO-ID for this meeting.
  #
  # Returns an SCO-ID string.
  def find_conference_key
    unless conference_key.present?
      self.conference_key = meeting_folder.
        contents.
        xpath("//sco[name=#{meeting_name.inspect}]").
        attr('sco-id').
        value
    end

    conference_key
  end

  # Internal: Register a participant as a host.
  #
  # user - The user to add as a conference admin.
  #
  # Returns the CanvasConnect::ConnectUser.
  def add_host(user)
    connect_user = AdobeConnect::User.find(user) || AdobeConnect::User.create(user)
    connect_service.permissions_update(
      :acl_id => find_conference_key,
      :principal_id => connect_user.id,
      :permission_id => 'host')

    connect_user
  end

  # Internal: Create a new Connect meeting.
  #
  # Returns nothing.
  def create_meeting
    params = { :type => 'meeting',
               :name => meeting_name,
               :folder_id => meeting_folder.id,
               :date_begin => start_at.iso8601,
               :url_path => meeting_url_suffix }
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
    result = connect_service.sco_by_url(:url_path => meeting_url_suffix)
    result.body.xpath('//status[@code="ok"]').present?
  end

  def meeting_name
    @cached_meeting_name ||= generate_meeting_name
  end

  def meeting_url
    @cached_meeting_url ||= generate_meeting_url
  end

  def meeting_url_suffix
    @cached_meeting_url_suffix ||= generate_meeting_url_suffix
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

  # Internal: Generate the base URL for the meeting.
  #
  # Returns a meeting string.
  def generate_meeting_url
    "#{config[:domain]}/#{meeting_url_suffix}"
  end

  # Internal: Generate a URL suffix for this conference.
  #
  # Returns a URL suffix string of format "canvas-meeting-:id".
  def generate_meeting_url_suffix
    "canvas-meeting-#{self.id}"
  end
end

