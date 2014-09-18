module Policies
  class LoggedInUser
    def initialize(account_service)
      @account_service = account_service
    end

    def can?(command)
      user = @account_service.answer Queries::FindUser.new(id: command.actor_id)
      !!user
    end
  end

  class TaskOwner
    def initialize(task_service, task_id_attribute)
      @task_service = task_service
      @task_id_attribute = task_id_attribute
    end

    def can?(command)
      task = @task_service.answer Queries::FindTask.new(id: command.send(@task_id_attribute))
      task && task.created_by == command.actor_id
    end
  end

  class Admin
    def initialize(account_service)
      @account_service = account_service
    end

    def can?(command)
      user = @account_service.answer Queries::FindUser.new(id: command.actor_id)
      user && user.admin
    end
  end

  class AndPolicy
    def initialize(policies)
      @policies = policies
    end

    def can?(command)
      @policies.all? { |p| p.can?(command) }
    end
  end

  class OrPolicy
    def initialize(policies)
      @policies = policies
    end

    def can?(command)
      @policies.any? { |p| p.can?(command) }
    end
  end

  class NoPolicy
    def can?(command)
      true
    end
  end
end
