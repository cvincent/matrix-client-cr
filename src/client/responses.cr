require "json"

class MatrixOrg::Client
  module Responses
    abstract struct Base
      include JSON::Serializable
    end

    struct Error < Base
      property errcode : String
      property error : String
    end

    struct Empty < Base
      def initialize(pull : JSON::PullParser)
        raise "Not empty" unless pull.read_raw == "{}"
      end
    end

    struct Versions < Base
      property versions : Array(String)
      property unstable_features : Hash(String, Bool)
    end

    struct Whoami < Base
      property user_id : String
    end

    struct Profile < Base
      property avatar_url : String | Nil
      property displayname : String
    end

    struct ProfileAvatarUrl < Base
      property avatar_url : String
    end

    struct ProfileDisplayname < Base
      property displayname : String
    end

    struct Register < Base
      property access_token : String
      property device_id : String
      property user_id : String
    end

    struct RegisterAvailable < Base
      property available : Bool
    end

    # TODO: This doesn't raise on error responses
    UserAccountData = Hash(String, String)
    UserRoomAccountData = Hash(String, String)

    struct UserRoomTags < Base
      property tags : Hash(String, Hash(String, Float32))
    end

    struct UserDirectorySearch < Base
      struct Result < Base
        property avatar_url : String | Nil
        property display_name : String
        property user_id : String
      end

      property limited : Bool
      property results : Array(Result)
    end

    struct Capabilities < Base
      property capabilities : JSON::Any
    end

    struct CreateRoom < Base
      property room_id : String
      property room_alias : String
    end

    struct RoomByAlias < Base
      property room_id : String
      property servers : Array(String)
    end

    struct RoomAliases < Base
      property aliases : Array(String)
    end

    struct EventId < Base
      property event_id : String
    end

    struct JoinRoom < Base
      property room_id : String
    end

    struct JoinedRooms < Base
      property joined_rooms : Array(String)
    end

    struct Presence < Base
      property last_active_ago : Int32 | Nil
      property presence : String
    end

    # TODO: This doesn't raise on error responses
    MediaConfig = JSON::Any

    struct Upload < Base
      property content_uri : String
    end
  end
end
