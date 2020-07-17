require "http"
require "./client/responses"

class MatrixOrg::Client
  VERSION = "0.1.0"
  # ENDPOINTS = [] of Tuple(String, String, Responses::Base.class)

  def initialize(@base_url : String, @access_token : String? = nil)
    @http = HTTP::Client.new(@base_url, nil, true)
    @headers = HTTP::Headers{} of String => String

    if @access_token
      @headers = HTTP::Headers{"Authorization" => "Bearer #{@access_token}"}
    end
  end

  macro endpoint(http_method, method_name, endpoint_path, response = nil)
    # ENDPOINTS.push({"{{http_method}}", "{{method_name}}", Responses::{{response || method_name.name.camelcase}}})

    def {{method_name}}(user_id : String? = nil, *params, data : NamedTuple? = nil)
      data = data.to_json rescue nil
      puts data
      json = @http.{{http_method}}(path({{endpoint_path}}, user_id, params), @headers, data).body
      puts json

      begin
        Responses::{{response || method_name.name.camelcase}}.from_json(json)
      rescue e
        begin
          Responses::Error.from_json(json)
        rescue
          raise e
        end
      end
    end
  end

  endpoint get, versions, "versions"
  endpoint get, whoami, "/_matrix/client/r0/account/whoami"
  endpoint get, profile, "/_matrix/client/r0/profile/%user_id"
  endpoint get, profile_avatar_url, "/_matrix/client/r0/profile/%user_id/avatar_url"
  endpoint put, update_profile_avatar_url, "/_matrix/client/r0/profile/%user_id/avatar_url", Empty
  endpoint get, profile_displayname, "/_matrix/client/r0/profile/%user_id/displayname"
  endpoint put, update_profile_displayname, "/_matrix/client/r0/profile/%user_id/displayname", Empty
  endpoint post, register, "/_matrix/client/r0/register"
  endpoint get, register_available, "/_matrix/client/r0/register/available"
  endpoint get, user_account_data, "/_matrix/client/r0/user/%user_id/account_data/%type"
  endpoint put, set_user_account_data, "/_matrix/client/r0/user/%user_id/account_data/%type", Empty
  endpoint get, user_room_account_data, "/_matrix/client/r0/user/%user_id/rooms/%room_id/account_data/%type"
  endpoint put, set_user_room_account_data, "/_matrix/client/r0/user/%user_id/rooms/%room_id/account_data/%type", Empty
  endpoint get, user_room_tags, "/_matrix/client/r0/user/%user_id/rooms/%room_id/tags"
  endpoint delete, delete_user_room_tag, "/_matrix/client/r0/user/%user_id/rooms/%room_id/tags/%tag", Empty
  endpoint put, set_user_room_tag, "/_matrix/client/r0/user/%user_id/rooms/%room_id/tags/%tag", Empty
  endpoint post, user_directory_search, "/_matrix/client/r0/user_directory/search"
  endpoint get, capabilities, "/_matrix/client/r0/capabilities"
  endpoint post, create_room, "/_matrix/client/r0/createRoom"
  endpoint delete, delete_room_alias, "/_matrix/client/r0/directory/room/%room_alias", Empty
  endpoint get, room_by_alias, "/_matrix/client/r0/directory/room/%room_alias"
  endpoint put, add_room_alias, "/_matrix/client/r0/directory/room/%room_alias", Empty
  endpoint get, room_aliases, "/_matrix/client/r0/rooms/%room_id/aliases"
  endpoint post, set_read_receipt, "/_matrix/client/r0/rooms/%room_id/receipt/m.read/%event_id", Empty
  endpoint put, redact_room_event, "/_matrix/client/r0/rooms/%room_id/redact/%event_id/%txn_id", EventId
  endpoint put, send_message, "/_matrix/client/r0/rooms/%room_id/send/%event_type/%txn_id", EventId
  endpoint put, set_typing, "/_matrix/client/r0/rooms/%room_id/typing/%user_id", Empty
  endpoint post, join_room, "/_matrix/client/r0/join/%room_id_or_alias"
  endpoint get, joined_rooms, "/_matrix/client/r0/joined_rooms"
  endpoint post, invite, "/_matrix/client/r0/rooms/%room_id/invite", Empty
  endpoint post, leave_room, "/_matrix/client/r0/rooms/%room_id/leave", Empty
  endpoint get, presence, "/_matrix/client/r0/presence/%user_id/status"
  endpoint put, set_presence, "/_matrix/client/r0/presence/%user_id/status", Empty
  endpoint post, set_read_markers, "/_matrix/client/r0/rooms/%room_id/read_markers", Empty
  endpoint post, set_read_markers, "/_matrix/client/r0/rooms/%room_id/read_markers", Empty
  endpoint get, media_config, "/_matrix/media/r0/config"

  def download_media(server_name : String, media_id : String)
    @http.get("/_matrix/media/r0/download/#{server_name}/#{media_id}")
  end

  def download_media(server_name : String, media_id : String, filename : String)
    @http.get("/_matrix/media/r0/download/#{server_name}/#{media_id}/filename")
  end

  def upload_media(filename, file)
    content_type_ch = Channel(String).new(1)
    io = IO::Memory.new

    HTTP::FormData.build(io) do |fd|
      content_type_ch.send(fd.content_type)
      metadata = HTTP::FormData::FileMetadata.new(filename: file.path)
      fd.file("file", file, metadata)
    end

    headers = @headers.dup
    headers["Content-Type"] = content_type_ch.receive

    json = @http.post("/_matrix/media/r0/upload?filename=#{filename}", headers, io).body

    begin
      Responses::Upload.from_json(json)
    rescue e
      begin
        Responses::Error.from_json(json)
      rescue
        raise e
      end
    end
  end

  private def path(path : String, user_id : String?, params : Tuple)
    params.each do |p|
      path = path.sub(/%[\w_]+/, p)
    end
    puts path

    if user_id
      "#{path}?user_id=#{user_id}"
    else
      path
    end
  end
end
