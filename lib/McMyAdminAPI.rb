#!/usr/bin/ruby
require "McMyAdminAPI/version"
require 'net/http'
require 'json'
require 'uri'

module CodeForKids
  class McMyAdminAPI
    #initializes the connection. Sets the session_id
    #host and port will be saved for arguments for each request

    def initialize(host, user, pass, port = '8080')
      @host = host
      @port = port
      login(user, pass)
    end

    def status
      request({req: 'GetStatus'})
    end

    #AddGroupValue
    ##########
    # group - The group affected - string
    ##########
    # type - controls which info is changed - string
    # type takes one of the following:
    # groupslist (No group needs to be specified, used to add new groups)
    # groupmembers (Add the user in 'value' as a member)
    # groupcommands (Add the command in 'value' as a member)
    # Color
    # Inherits
    # CanBuild
    # CanInteract
    # Prefix
    # Suffix
    ##########
    # value - the value to be set by the method
    # CanBuild and CanInteract take boolean
    # the rest take string

    def add_group_value(group, type, value)
      request({req: 'addgroupvalue', group: group, type: type, value: value})
    end

    # AddLicence
    ##########
    # newkey - String

    def add_licence(newkey)
      request({req: 'addlicence', newkey: newkey})
    end

    # AddScheduleItem
    ##########
    # hours, mins - int32
    # TriggerEvent - TriggerEvents[Enum:Int32]
    # Type - EventType[Enum:Int32]
    # Param - *Optional* - String

    def add_schedule_item(hours, mins, trigger_event, type, param = '')
      request({req: 'addscheduleitem', hours: hours, mins: mins, triggerevent: trigger_event, type: type, param: param})
    end

    # ChangePassword
    ##########
    # old_pass - string
    # new_pass - string

    def change_password(old_pass, new_pass)
      request({req: 'changepassword', oldpassword: old_pass, newpassword: new_pass})
    end

    # ChangeUserPassword
    ##########
    # user - string
    # pass - string

    def change_user_password(user, pass)
      request({req: 'changeuserpassword', username: user, newpassword: pass})
    end

    # CreateGroup
    ##########
    # name - string

    def create_group(name)
      request({req: 'creategroup', name: name})
    end

    # CreateUser
    ##########
    # username - string

    def create_user(username)
      request({req: 'createuser', newusername: username})
    end

    # DeleteBackup
    ##########
    # backup_ID - string

    def delete_backup(backup_ID)
      request({req: 'deletebackup', backupid: backup_ID})
    end

    # Whitelist a User
    ##########
    # username - string

    def whitelist(username)
      request({req: 'sendchat', message: "/whitelist add #{username}"})

      sleep 0.1 # Give server time to add to whitelist

      if is_maybe_whitelisted?(username)
        puts "Successfully added #{username} to whitelist."
      else
        raise "May not have added #{username} to whitelist, please manually check with the whitelist_list command"
      end
    end

    # Delete a user from whitelist
    ##########
    # username - string

    def remove_whitelist(username)
      request({req: 'sendchat', message: "/whitelist remove #{username}"})
    end

    private

    attr_accessor :session_id, :host, :port

    def request(params_hash)
      response = perform_request(params_hash)
      case response
      when Net::HTTPSuccess
        JSON.parse response.body
      else
        response.error!
      end
    end

    def login(user, pass)
      response = perform_request({req: 'Login', username: user, password: pass})
      json_response = JSON.parse response.body

      if json_response["success"]
        @session_id = json_response['MCMASESSIONID']
        json_response
      else
        raise "Could not authenticate user. Status Code: #{json_response['status']}"
      end
    end

    def perform_request(params_hash)
      params_hash = params_hash.merge({Token: '', MCMASESSIONID: @session_id})
      query_params = URI.encode_www_form(params_hash)

      url = URI.parse("http://#{@host}:#{@port}/data.json?#{query_params}")
      http = Net::HTTP.new(url.host, url.port)
      response = http.get("#{url.path}?#{url.query.to_s}", {'Content-Type' => 'application/json', 'Accept' => 'application/json'})
    end

    def is_maybe_whitelisted?(username)
      chat_data = request({req: 'getchat', since: 1})["chatdata"]
      last_message = chat_data.last['message']
      last_message.include?("Added #{username} to white-list")
    end

  end
end