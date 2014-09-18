require 'virtus'

module Commands
  class CommandFromActor
    include Virtus.model

    attribute :actor_id, String
  end

  class CreateTask < CommandFromActor
    attribute :id, String
    attribute :title, String
    attribute :actor_id, String
  end

  class InviteUserToTask < CommandFromActor
    attribute :user_id, String
    attribute :task_id, String
  end

  class AssignTask < CommandFromActor
    attribute :task_id, String
    attribute :user_id, String
  end

  class RegisterUser
    include Virtus.model

    attribute :id, String
    attribute :name, String
  end

  class MakeAdmin < CommandFromActor
    attribute :user_id, String
  end

  class DeleteTask < CommandFromActor
    attribute :task_id, String
  end
end
