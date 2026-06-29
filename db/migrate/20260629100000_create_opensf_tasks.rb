# OPENSF: agenda/tarefas — retornos de conversa + tarefas atribuídas por supervisor/gerente
class CreateOpensfTasks < ActiveRecord::Migration[7.1]
  def change
    create_table :opensf_tasks do |t|
      t.bigint :account_id, null: false
      t.bigint :assignee_id, null: false      # usuário que executa a tarefa
      t.bigint :created_by_id, null: false     # quem criou (próprio ou gestor)
      t.bigint :conversation_id                # opcional: retorno ligado à conversa
      t.bigint :contact_id                     # opcional
      t.string :title, null: false
      t.text :description
      t.string :category                       # motivo: aguardando_contracheque, vai_pensar, etc
      t.datetime :due_at, null: false
      t.string :status, null: false, default: 'pending' # pending, done, cancelled
      t.datetime :completed_at
      t.timestamps
    end

    add_index :opensf_tasks, [:account_id, :assignee_id, :due_at]
    add_index :opensf_tasks, [:account_id, :status]
    add_index :opensf_tasks, :conversation_id
  end
end
