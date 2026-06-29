<script setup>
// OPENSF: agenda de retornos e tarefas (agente vê as suas; gestor/supervisor atribuem à equipe)
import { ref, computed, onMounted } from 'vue';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';

const store = useStore();

const currentUser = useMapGetter('getCurrentUser');
const agents = useMapGetter('agents/getAgents');

const accountId = computed(
  () =>
    currentUser.value?.account_id ||
    window.location.pathname.match(/accounts\/(\d+)/)?.[1]
);
const accessToken = computed(() => currentUser.value?.access_token);
const apiBase = computed(() => `/api/v1/accounts/${accountId.value}/opensf/tasks`);

const tasks = ref([]);
const loading = ref(false);
const showForm = ref(false);
const teamView = ref(false);

// Papel OpenSF do usuário atual (derivado da lista de agentes)
const myRole = computed(() => {
  const me = agents.value?.find(a => a.id === currentUser.value?.id);
  return me?.opensf_role || '';
});
const canAssign = computed(() => ['manager', 'supervisor'].includes(myRole.value));

const CATEGORIES = [
  { value: '', label: 'Sem categoria' },
  { value: 'pediu_retorno', label: 'Pediu retorno' },
  { value: 'aguardando_contracheque', label: 'Aguardando contracheque' },
  { value: 'vai_pensar', label: 'Vai pensar' },
  { value: 'documentacao', label: 'Documentação pendente' },
  { value: 'tarefa', label: 'Tarefa' },
  { value: 'outro', label: 'Outro' },
];

const categoryLabel = val =>
  CATEGORIES.find(c => c.value === val)?.label || '';

// Formulário
const form = ref({
  title: '',
  description: '',
  category: '',
  due_at: '',
  assignee_id: '',
});

const resetForm = () => {
  form.value = {
    title: '',
    description: '',
    category: '',
    due_at: defaultDueAt(),
    assignee_id: '',
  };
};

function defaultDueAt() {
  // amanhã 09:00 local, formatado para datetime-local
  const d = new Date();
  d.setDate(d.getDate() + 1);
  d.setHours(9, 0, 0, 0);
  const pad = n => String(n).padStart(2, '0');
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}T${pad(d.getHours())}:${pad(d.getMinutes())}`;
}

async function fetchTasks() {
  loading.value = true;
  try {
    const params = new URLSearchParams();
    if (teamView.value && canAssign.value) params.set('scope', 'team');
    const res = await fetch(`${apiBase.value}?${params.toString()}`, {
      headers: { api_access_token: accessToken.value },
    });
    tasks.value = await res.json();
  } catch {
    useAlert('Erro ao carregar agenda');
  } finally {
    loading.value = false;
  }
}

async function createTask() {
  if (!form.value.title || !form.value.due_at) {
    useAlert('Preencha título e data');
    return;
  }
  try {
    const payload = {
      task: {
        title: form.value.title,
        description: form.value.description,
        category: form.value.category,
        due_at: new Date(form.value.due_at).toISOString(),
        assignee_id: form.value.assignee_id || undefined,
      },
    };
    const res = await fetch(apiBase.value, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        api_access_token: accessToken.value,
      },
      body: JSON.stringify(payload),
    });
    if (!res.ok) throw new Error('falha');
    showForm.value = false;
    resetForm();
    await fetchTasks();
  } catch {
    useAlert('Erro ao criar tarefa');
  }
}

async function markDone(task) {
  try {
    await fetch(`${apiBase.value}/${task.id}`, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        api_access_token: accessToken.value,
      },
      body: JSON.stringify({ mark_done: true, task: { status: 'done' } }),
    });
    await fetchTasks();
  } catch {
    useAlert('Erro ao concluir tarefa');
  }
}

async function deleteTask(task) {
  try {
    await fetch(`${apiBase.value}/${task.id}`, {
      method: 'DELETE',
      headers: { api_access_token: accessToken.value },
    });
    await fetchTasks();
  } catch {
    useAlert('Erro ao remover tarefa');
  }
}

// Agrupamento
const startOfToday = () => {
  const d = new Date();
  d.setHours(0, 0, 0, 0);
  return d;
};
const endOfToday = () => {
  const d = new Date();
  d.setHours(23, 59, 59, 999);
  return d;
};

const pending = computed(() => tasks.value.filter(t => t.status === 'pending'));
const done = computed(() => tasks.value.filter(t => t.status === 'done'));

const overdue = computed(() =>
  pending.value.filter(t => new Date(t.due_at) < startOfToday())
);
const today = computed(() =>
  pending.value.filter(t => {
    const due = new Date(t.due_at);
    return due >= startOfToday() && due <= endOfToday();
  })
);
const upcoming = computed(() =>
  pending.value.filter(t => new Date(t.due_at) > endOfToday())
);

const fmtDateTime = iso =>
  new Date(iso).toLocaleString('pt-BR', {
    day: '2-digit',
    month: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
  });

const goToConversation = task => {
  if (!task.conversation_id) return;
  store.dispatch('setActiveInbox', null);
  window.location.href = `/app/accounts/${accountId.value}/conversations/${task.conversation_id}`;
};

onMounted(async () => {
  resetForm();
  try {
    await store.dispatch('agents/get');
  } catch {
    // ignore
  }
  await fetchTasks();
});
</script>

<template>
  <div class="flex flex-col h-full overflow-auto bg-slate-25 dark:bg-slate-900">
    <!-- Header -->
    <div class="flex items-center justify-between px-6 py-4 border-b border-slate-200 dark:border-slate-700">
      <div>
        <h1 class="text-lg font-semibold text-slate-800 dark:text-slate-100">Agenda</h1>
        <p class="text-sm text-slate-500 dark:text-slate-400">
          Retornos e tarefas do dia
        </p>
      </div>
      <div class="flex items-center gap-2">
        <button
          v-if="canAssign"
          class="text-sm px-3 py-1.5 rounded-lg border border-slate-300 dark:border-slate-600"
          :class="teamView ? 'bg-woot-500 text-white border-woot-500' : 'text-slate-600 dark:text-slate-300'"
          @click="teamView = !teamView; fetchTasks()"
        >
          {{ teamView ? 'Vendo: Equipe' : 'Vendo: Minhas' }}
        </button>
        <button
          class="text-sm px-4 py-1.5 rounded-lg bg-woot-500 text-white hover:bg-woot-600 flex items-center gap-1.5"
          @click="showForm = true"
        >
          <span class="i-lucide-plus" />
          Nova tarefa
        </button>
      </div>
    </div>

    <div class="flex-1 p-6 max-w-4xl w-full mx-auto">
      <!-- Loading -->
      <div v-if="loading" class="space-y-3">
        <div v-for="i in 3" :key="i" class="h-16 rounded-xl bg-slate-100 dark:bg-slate-800 animate-pulse" />
      </div>

      <template v-else>
        <!-- Atrasadas -->
        <section v-if="overdue.length" class="mb-6">
          <h2 class="text-sm font-semibold text-rose-600 dark:text-rose-400 mb-2 flex items-center gap-1.5">
            <span class="i-lucide-alert-triangle" /> Atrasadas ({{ overdue.length }})
          </h2>
          <div class="space-y-2">
            <div
              v-for="task in overdue"
              :key="task.id"
              class="task-card border-rose-200 dark:border-rose-900"
            >
              <div class="flex-1 min-w-0" @click="goToConversation(task)">
                <p class="font-medium text-slate-800 dark:text-slate-100 truncate">{{ task.title }}</p>
                <p class="text-xs text-slate-500 dark:text-slate-400">
                  {{ fmtDateTime(task.due_at) }}
                  <span v-if="task.category"> · {{ categoryLabel(task.category) }}</span>
                  <span v-if="teamView"> · {{ task.assignee_name }}</span>
                </p>
              </div>
              <div class="flex items-center gap-1">
                <button class="icon-btn" title="Concluir" @click="markDone(task)">
                  <span class="i-lucide-check text-emerald-600" />
                </button>
                <button class="icon-btn" title="Remover" @click="deleteTask(task)">
                  <span class="i-lucide-trash-2 text-slate-400" />
                </button>
              </div>
            </div>
          </div>
        </section>

        <!-- Hoje -->
        <section class="mb-6">
          <h2 class="text-sm font-semibold text-slate-700 dark:text-slate-200 mb-2 flex items-center gap-1.5">
            <span class="i-lucide-calendar-check text-woot-500" /> Hoje ({{ today.length }})
          </h2>
          <div v-if="today.length" class="space-y-2">
            <div v-for="task in today" :key="task.id" class="task-card border-slate-200 dark:border-slate-700">
              <div class="flex-1 min-w-0" @click="goToConversation(task)">
                <p class="font-medium text-slate-800 dark:text-slate-100 truncate">{{ task.title }}</p>
                <p class="text-xs text-slate-500 dark:text-slate-400">
                  {{ fmtDateTime(task.due_at) }}
                  <span v-if="task.category"> · {{ categoryLabel(task.category) }}</span>
                  <span v-if="teamView"> · {{ task.assignee_name }}</span>
                </p>
              </div>
              <div class="flex items-center gap-1">
                <button class="icon-btn" title="Concluir" @click="markDone(task)">
                  <span class="i-lucide-check text-emerald-600" />
                </button>
                <button class="icon-btn" title="Remover" @click="deleteTask(task)">
                  <span class="i-lucide-trash-2 text-slate-400" />
                </button>
              </div>
            </div>
          </div>
          <p v-else class="text-sm text-slate-400 py-3">Nada para hoje. 🎉</p>
        </section>

        <!-- Próximas -->
        <section v-if="upcoming.length" class="mb-6">
          <h2 class="text-sm font-semibold text-slate-700 dark:text-slate-200 mb-2 flex items-center gap-1.5">
            <span class="i-lucide-clock text-slate-400" /> Próximas ({{ upcoming.length }})
          </h2>
          <div class="space-y-2">
            <div v-for="task in upcoming" :key="task.id" class="task-card border-slate-200 dark:border-slate-700">
              <div class="flex-1 min-w-0" @click="goToConversation(task)">
                <p class="font-medium text-slate-800 dark:text-slate-100 truncate">{{ task.title }}</p>
                <p class="text-xs text-slate-500 dark:text-slate-400">
                  {{ fmtDateTime(task.due_at) }}
                  <span v-if="task.category"> · {{ categoryLabel(task.category) }}</span>
                  <span v-if="teamView"> · {{ task.assignee_name }}</span>
                </p>
              </div>
              <div class="flex items-center gap-1">
                <button class="icon-btn" title="Concluir" @click="markDone(task)">
                  <span class="i-lucide-check text-emerald-600" />
                </button>
                <button class="icon-btn" title="Remover" @click="deleteTask(task)">
                  <span class="i-lucide-trash-2 text-slate-400" />
                </button>
              </div>
            </div>
          </div>
        </section>

        <!-- Concluídas -->
        <section v-if="done.length" class="mb-6">
          <h2 class="text-sm font-semibold text-slate-400 mb-2">Concluídas ({{ done.length }})</h2>
          <div class="space-y-2">
            <div
              v-for="task in done"
              :key="task.id"
              class="task-card border-slate-100 dark:border-slate-800 opacity-60"
            >
              <div class="flex-1 min-w-0">
                <p class="font-medium text-slate-500 line-through truncate">{{ task.title }}</p>
                <p class="text-xs text-slate-400">
                  {{ fmtDateTime(task.due_at) }}
                  <span v-if="teamView"> · {{ task.assignee_name }}</span>
                </p>
              </div>
              <button class="icon-btn" title="Remover" @click="deleteTask(task)">
                <span class="i-lucide-trash-2 text-slate-400" />
              </button>
            </div>
          </div>
        </section>
      </template>
    </div>

    <!-- Modal Nova Tarefa -->
    <div
      v-if="showForm"
      class="fixed inset-0 z-50 flex items-center justify-center bg-black/40"
      @click.self="showForm = false"
    >
      <div class="bg-white dark:bg-slate-800 rounded-xl shadow-xl w-full max-w-md p-6">
        <h3 class="text-lg font-semibold text-slate-800 dark:text-slate-100 mb-4">Nova tarefa</h3>

        <label class="block mb-3">
          <span class="text-sm text-slate-600 dark:text-slate-300">Título</span>
          <input
            v-model="form.title"
            type="text"
            class="mt-1 w-full border border-slate-300 dark:border-slate-600 rounded-lg px-3 py-2 bg-white dark:bg-slate-900"
            placeholder="ex: Ligar para João sobre contracheque"
          />
        </label>

        <label class="block mb-3">
          <span class="text-sm text-slate-600 dark:text-slate-300">Quando</span>
          <input
            v-model="form.due_at"
            type="datetime-local"
            class="mt-1 w-full border border-slate-300 dark:border-slate-600 rounded-lg px-3 py-2 bg-white dark:bg-slate-900"
          />
        </label>

        <label class="block mb-3">
          <span class="text-sm text-slate-600 dark:text-slate-300">Categoria</span>
          <select
            v-model="form.category"
            class="mt-1 w-full border border-slate-300 dark:border-slate-600 rounded-lg px-3 py-2 bg-white dark:bg-slate-900"
          >
            <option v-for="c in CATEGORIES" :key="c.value" :value="c.value">{{ c.label }}</option>
          </select>
        </label>

        <label v-if="canAssign" class="block mb-3">
          <span class="text-sm text-slate-600 dark:text-slate-300">Atribuir para</span>
          <select
            v-model="form.assignee_id"
            class="mt-1 w-full border border-slate-300 dark:border-slate-600 rounded-lg px-3 py-2 bg-white dark:bg-slate-900"
          >
            <option value="">Eu mesmo</option>
            <option v-for="a in agents" :key="a.id" :value="a.id">{{ a.name }}</option>
          </select>
        </label>

        <label class="block mb-4">
          <span class="text-sm text-slate-600 dark:text-slate-300">Observação (opcional)</span>
          <textarea
            v-model="form.description"
            rows="2"
            class="mt-1 w-full border border-slate-300 dark:border-slate-600 rounded-lg px-3 py-2 bg-white dark:bg-slate-900"
          />
        </label>

        <div class="flex justify-end gap-2">
          <button
            class="px-4 py-2 text-sm text-slate-600 dark:text-slate-300"
            @click="showForm = false"
          >
            Cancelar
          </button>
          <button
            class="px-4 py-2 text-sm rounded-lg bg-woot-500 text-white hover:bg-woot-600"
            @click="createTask"
          >
            Criar
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.task-card {
  @apply flex items-center gap-3 rounded-xl border bg-white dark:bg-slate-800 px-4 py-3 cursor-pointer hover:shadow-sm transition;
}
.icon-btn {
  @apply p-1.5 rounded-md hover:bg-slate-100 dark:hover:bg-slate-700;
}
</style>
