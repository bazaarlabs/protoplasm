require "protoplasm/version"

# Protoplasm 
# This defines BlockingClient and EMServer.
module Protoplasm
  autoload :BlockingClient, "protoplasm/client/blocking_client"
  autoload :EMServer,       "protoplasm/server/em_server"
  autoload :Types,          "protoplasm/types/types"
end
