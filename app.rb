require 'securerandom'

require_relative './commands'
require_relative './queries'
require_relative './policies'
require_relative './command_handlers'

class Persistence
  def initialize
    @entities = []
  end

  def find(id)
    @entities.find { |e| e.id == id }
  end

  def save(entity)
    @entities << entity
  end

  def update(entity)
    delete(entity.id)
    save entity
  end

  def delete(id)
    @entities.delete_if { |e| e.id == id }
  end

  def all
    @entities
  end
end

module DTOs
  class User
    include Virtus.model

    attribute :id, String
    attribute :name, String
    attribute :admin, Boolean
  end

  class Task
    include Virtus.model

    attribute :id, String
    attribute :title, String
    attribute :created_by, String
    attribute :invited_users, Array[String]
  end
end

class AccountService
  def initialize(memory)
    @memory = memory
  end

  def handle(command)
    case command
    when Commands::RegisterUser
      @memory.save DTOs::User.new(id: command.id, name: command.name, admin: false)
    when Commands::MakeAdmin
      user = @memory.find(command.user_id)
      user.admin = true
      @memory.update user
    else
      raise "can't handle it"
    end
  end

  def answer(query)
    case query
    when Queries::FindUser
      @memory.find(query.id)
    else
      raise "can't answer it"
    end
  end
end

class TaskService
  def initialize(memory)
    @memory = memory
  end

  def handle(command)
    case command
    when Commands::CreateTask
      @memory.save DTOs::Task.new(id: command.id, title: command.title, created_by: command.actor_id)
    when Commands::InviteUserToTask
      task = @memory.find command.task_id
      task.invited_users << command.user_id
      @memory.update task
    when Commands::DeleteTask
      @memory.delete command.task_id
    else
      raise "can't handle it"
    end
  end

  def answer(query)
    case query
    when Queries::TasksForUser
      @memory.all.select { |t| t.created_by == query.user_id || t.invited_users.include?(query.user_id) }
    when Queries::FindTask
      @memory.find query.id
    end
  end
end


class App
  attr_reader :account_service

  def initialize
    @account_service = AccountService.new(Persistence.new)
    @task_service = TaskService.new(Persistence.new)
  end

  def handle(command)
    handler_for_command(command.class).handle(command)
  end

  def answer(query)
    handler_for_query(query.class).answer(query)
  end

  private
    def handler_for_command(klass)
      # TODO add cache in front of account_service (class => return value; maybe more sophisticated
      handlers = {
        Commands::RegisterUser => AuthHandler.new(
                                    Policies::NoPolicy.new,
                                    @account_service),
        Commands::CreateTask => AuthHandler.new(
                                  Policies::LoggedInUser.new(@account_service),
                                  @task_service),
        Commands::InviteUserToTask => AuthHandler.new(
                                        Policies::AndPolicy.new([
                                          Policies::TaskOwner.new(@task_service, :task_id),
                                          Policies::LoggedInUser.new(@account_service)]),
                                        @task_service),
        Commands::MakeAdmin => AuthHandler.new(
                                 Policies::Admin.new(@account_service),
                                 @account_service),
        Commands::DeleteTask => AuthHandler.new(
                                  Policies::OrPolicy.new([
                                    Policies::Admin.new(@account_service),
                                    Policies::TaskOwner.new(@task_service, :task_id)]),
                                  @task_service)
      }
      result = {}
      handlers.each do |klass, handler|
        result[klass] = LogHandler.new(handler)
      end
      result[klass]
    end

    def handler_for_query(klass)
      {
        Queries::FindUser => @account_service,
        Queries::TasksForUser => @task_service
      }[klass]
    end
end

app = App.new
user_id = SecureRandom.uuid
user_2_id = SecureRandom.uuid
app.handle Commands::RegisterUser.new(name: "tim", id: user_id)
app.handle Commands::RegisterUser.new(name: "peter", id: user_2_id)
task_id = SecureRandom.uuid
task_2_id = SecureRandom.uuid
app.handle Commands::CreateTask.new(id: task_id, title: "Some title", actor_id: user_id)
app.handle Commands::CreateTask.new(id: task_2_id, title: "Some other title", actor_id: user_2_id)
app.handle Commands::InviteUserToTask.new(user_id: user_id, task_id: task_2_id, actor_id: user_2_id)

# We need to skip the app, because no one is admin yet.
app.account_service.handle Commands::MakeAdmin.new(user_id: user_id)
app.handle Commands::DeleteTask.new(task_id: task_2_id, actor_id: user_2_id)

puts
puts "My tasks:"
puts "-----"
puts app.answer(Queries::TasksForUser.new(user_id: user_id)).map { |t| "* #{t.id[0..5]} | #{t.title}" }.join("\n")
