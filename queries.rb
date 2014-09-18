require 'virtus'

module Queries
  class QueryFromActor
    include Virtus.model

    attribute :actor_id, String
  end

  class FindUser < QueryFromActor
    attribute :id, String
  end

  class TasksForUser < QueryFromActor
    attribute :user_id, String
  end

  class FindTask < QueryFromActor
    attribute :id, String
  end
end
