# OPENSF: agenda/tarefas — CRUD com permissão por papel OpenSF
class Api::V1::Accounts::Opensf::TasksController < Api::V1::Accounts::BaseController
  before_action :set_task, only: [:update, :destroy]

  # GET index — por padrão mostra as tarefas do próprio usuário.
  # Gestor/supervisor podem passar ?assignee_id= ou ?scope=team para ver a equipe.
  def index
    tasks = scoped_tasks
    tasks = tasks.where(status: params[:status]) if params[:status].present?

    if params[:date].present?
      date = Date.parse(params[:date])
      tasks = tasks.due_on(date)
    end

    render json: tasks.includes(:assignee, :created_by).order(due_at: :asc).map { |t| serialize(t) }
  end

  def create
    assignee_id = resolve_assignee_id
    return render_forbidden unless can_assign_to?(assignee_id)

    task = OpensfTask.new(task_params)
    task.account_id = Current.account.id
    task.assignee_id = assignee_id
    task.created_by = current_user
    task.save!
    render json: serialize(task), status: :created
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def update
    @task.update!(update_params)
    @task.mark_done! if params[:mark_done]
    render json: serialize(@task)
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def destroy
    @task.destroy!
    head :no_content
  end

  private

  def set_task
    @task = scoped_tasks.find(params[:id])
  end

  # Tarefas visíveis conforme o papel
  def scoped_tasks
    base = OpensfTask.where(account_id: Current.account.id)

    case opensf_role
    when 'manager'
      params[:assignee_id].present? ? base.for_assignee(params[:assignee_id]) : base
    when 'supervisor'
      ids = supervised_user_ids
      if params[:assignee_id].present? && ids.include?(params[:assignee_id].to_i)
        base.for_assignee(params[:assignee_id])
      elsif params[:scope] == 'team'
        base.where(assignee_id: ids)
      else
        base.for_assignee(current_user.id)
      end
    else
      base.for_assignee(current_user.id)
    end
  end

  def resolve_assignee_id
    requested = params.dig(:task, :assignee_id) || params[:assignee_id]
    requested.presence&.to_i || current_user.id
  end

  def can_assign_to?(assignee_id)
    return true if assignee_id == current_user.id

    case opensf_role
    when 'manager'
      Current.account.users.exists?(id: assignee_id)
    when 'supervisor'
      supervised_user_ids.include?(assignee_id)
    else
      false
    end
  end

  def supervised_user_ids
    inbox_ids = Current.account.inboxes
                       .joins(:inbox_members)
                       .where(inbox_members: { user_id: current_user.id })
                       .pluck(:id)
    User.joins(:inbox_members)
        .where(inbox_members: { inbox_id: inbox_ids })
        .distinct.pluck(:id)
  end

  def opensf_role
    @opensf_role ||= AccountUser.find_by(user: current_user, account: Current.account)&.opensf_role
  end

  def task_params
    params.require(:task).permit(
      :title, :description, :category, :due_at, :conversation_id, :contact_id
    )
  end

  def update_params
    params.require(:task).permit(:title, :description, :category, :due_at, :status)
  end

  def render_forbidden
    render json: { error: 'sem permissao para atribuir esta tarefa' }, status: :forbidden
  end

  def serialize(task)
    {
      id: task.id,
      title: task.title,
      description: task.description,
      category: task.category,
      due_at: task.due_at,
      status: task.status,
      completed_at: task.completed_at,
      conversation_id: task.conversation_id,
      contact_id: task.contact_id,
      assignee_id: task.assignee_id,
      assignee_name: task.assignee&.name,
      created_by_id: task.created_by_id,
      created_by_name: task.created_by&.name,
      created_at: task.created_at
    }
  end
end
