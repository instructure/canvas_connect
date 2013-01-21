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
  class Service
    attr_reader :username, :domain, :is_authenticated

    def initialize(username, password, domain)
      @username, @password, @domain = [username, password, domain]
    end

    # Public: Authenticate against the Adobe Connect server.
    #
    # Returns true.
    def log_in
      unless logged_in?
        response = login(:login => @username, :password => @password)
        if response.xpath('//status[@code="ok"]').empty?
          raise ConnectionError.new("Could not log in to #{@domain} as #{@username}.")
        end

      @is_authenticated = true
      end

      true
    end

    # Public: Determine if the current session is authenticated.
    #
    # Returns a boolean.
    def logged_in?
      @is_authenticated
    end

    # Public: Proxy any unknown methods to the Adobe Connect API.
    #
    # method - The snake-cased name of an Adobe Connect method, e.g. `common_info`.
    # args - Two optional arguments: a hash of GET params, and a skip_session boolean.
    #
    # Returns a CanvasConnect::Response.
    def method_missing(method, *args)
      action = "#{method}".dasherize
      params, skip_session = args
      params ||= {}

      request(action, params, !skip_session)
    end

    # Public: Create a new Connect session for the given user.
    #
    # user - A CanvasConnect::ConnectUser.
    # domain - The domain to authenticate against.
    def self.user_session(user, domain)
      service = CanvasConnect::Service.new(user.username, user.password, domain)
      service.log_in

      service.session_key
    end

    # Public: Get a session token for future requests.
    #
    # Returns a session token.
    def session_key
      unless @session_key
        response     = request('common-info', {}, false)
        @session_key = response.xpath('//cookie').text
      end

      @session_key
    end

    protected
    # Internal: Create and/or return a Net::HTTP instance.
    #
    # Returns a Net::HTTP instance.
    def client
      unless @client
        uri = URI.parse(@domain)
        @client = Net::HTTP.new(uri.host, uri.port)
        @client.use_ssl = (uri.scheme == 'https')
      end

      @client
    end

    # Internal: Make a request to the Adobe Connect API.
    #
    # action - The name of the Connect API action to call.
    # params - A hash of parameters to pass with the request. (default: {})
    # with_session - If true, make the request inside a new or existing session. (default: true)
    #
    # Returns a CanvasConnect::Response object.
    def request(action, params = {}, with_session = true)
      params[:session] = session_key if with_session
      response = client.get("/api/xml?action=#{action}#{format_params(params)}")

      CanvasConnect::Response.new(response.code, response.each_header { |h| }, response.body)
    rescue SocketError, TimeoutError => e
      # Return an empty, timed-out request.
      Rails.logger.error "Adobe Connect Request Error on #{action}: #{e.message}"
      CanvasConnect::Response.new(408, {}, '')
    end

    # Internal: Convert snake-cased hash keys to dashed.
    #
    # params - A hash of parameters with snake-cased string or symbol keys.
    #
    # Examples
    #
    #   format_params({param_name: 'value', other_param: 'value 2'})
    #
    #   # Returns "&param-name=value&other-param=value%202"
    #
    # Returns a query string prefixed with a '&' (because it assumes action will be included).
    def format_params(params)
      params.inject(['']) do |arr, p|
        key, value = p
        arr << "#{key.to_s.dasherize}=#{URI.escape(value.to_s)}"
      end.join('&')
    end
  end
end

