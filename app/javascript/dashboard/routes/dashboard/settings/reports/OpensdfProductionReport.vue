<script setup>
// OPENSF: KPI de produção individual do agente (propostas Corbee via codigo_corretor)
import { ref, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { useStore } from 'dashboard/composables/store';

const { t } = useI18n();
const store = useStore();

const kpis = ref(null);
const codigoCorretor = ref('');
const editingCodigo = ref(false);
const savingCodigo = ref(false);
const loading = ref(false);
const notConfigured = ref(false);

const accountId = store.getters['auth/getCurrentUser']?.account_id
  || window.location.pathname.match(/accounts\/(\d+)/)?.[1];

const apiBase = `/api/v1/accounts/${accountId}/opensf`;

async function fetchProfile() {
  try {
    const res = await fetch(`${apiBase}/agent_profile`, {
      headers: { api_access_token: store.getters['auth/getCurrentUser']?.access_token },
    });
    const data = await res.json();
    codigoCorretor.value = data.codigo_corretor || '';
  } catch {
    // silently ignore
  }
}

async function fetchKpis() {
  loading.value = true;
  notConfigured.value = false;
  try {
    const res = await fetch(`${apiBase}/production/kpis`, {
      headers: { api_access_token: store.getters['auth/getCurrentUser']?.access_token },
    });
    const data = await res.json();
    if (data.error) {
      notConfigured.value = data.error.includes('codigo_corretor');
      return;
    }
    kpis.value = data;
  } catch {
    useAlert('Erro ao carregar produção');
  } finally {
    loading.value = false;
  }
}

async function saveCodigo() {
  savingCodigo.value = true;
  try {
    const res = await fetch(`${apiBase}/agent_profile`, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        api_access_token: store.getters['auth/getCurrentUser']?.access_token,
      },
      body: JSON.stringify({ codigo_corretor: codigoCorretor.value }),
    });
    await res.json();
    editingCodigo.value = false;
    await fetchKpis();
  } catch {
    useAlert('Erro ao salvar código');
  } finally {
    savingCodigo.value = false;
  }
}

const fmt = val =>
  Number(val).toLocaleString('pt-BR', { style: 'currency', currency: 'BRL' });

const fmtN = val => Number(val).toLocaleString('pt-BR');

onMounted(async () => {
  await fetchProfile();
  await fetchKpis();
});
</script>

<template>
  <div class="p-6 max-w-5xl mx-auto">
    <!-- Header -->
    <div class="flex items-center justify-between mb-6">
      <div>
        <h2 class="text-xl font-semibold text-slate-800 dark:text-slate-100">
          Minha Produção
        </h2>
        <p class="text-sm text-slate-500 dark:text-slate-400 mt-0.5">
          Banco de Produção · {{ kpis?.mes_referencia || '—' }}
        </p>
      </div>

      <!-- Código do corretor -->
      <div class="flex items-center gap-2">
        <span class="text-sm text-slate-500 dark:text-slate-400">Código corretor:</span>
        <template v-if="editingCodigo">
          <input
            v-model="codigoCorretor"
            class="border border-slate-300 dark:border-slate-600 rounded px-2 py-1 text-sm w-28 bg-white dark:bg-slate-800"
            placeholder="ex: 424"
            @keyup.enter="saveCodigo"
          />
          <button
            class="text-sm px-3 py-1 bg-woot-500 text-white rounded hover:bg-woot-600 disabled:opacity-60"
            :disabled="savingCodigo"
            @click="saveCodigo"
          >
            Salvar
          </button>
          <button
            class="text-sm px-2 py-1 text-slate-500 hover:text-slate-700"
            @click="editingCodigo = false"
          >
            Cancelar
          </button>
        </template>
        <template v-else>
          <span class="font-mono text-sm font-medium text-slate-700 dark:text-slate-300">
            {{ codigoCorretor || '—' }}
          </span>
          <button
            class="text-xs text-woot-500 hover:underline"
            @click="editingCodigo = true"
          >
            Editar
          </button>
        </template>
      </div>
    </div>

    <!-- Not configured -->
    <div
      v-if="notConfigured"
      class="rounded-xl border border-amber-200 bg-amber-50 dark:bg-amber-900/20 dark:border-amber-700 p-6 text-center"
    >
      <p class="text-amber-800 dark:text-amber-200 font-medium">
        Configure seu código de corretor acima para visualizar sua produção.
      </p>
    </div>

    <!-- Loading -->
    <div v-else-if="loading" class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
      <div
        v-for="i in 4"
        :key="i"
        class="rounded-xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-800 p-5 animate-pulse h-28"
      />
    </div>

    <!-- KPI cards -->
    <div v-else-if="kpis" class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">

      <!-- Total de Propostas -->
      <div class="rounded-xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-800 p-5">
        <div class="flex items-start justify-between mb-3">
          <span class="text-sm text-slate-500 dark:text-slate-400 font-medium">Total de Propostas</span>
          <span class="i-lucide-file-text text-slate-400 text-lg" />
        </div>
        <p class="text-2xl font-bold text-slate-800 dark:text-slate-100">
          {{ fmtN(kpis.total_propostas) }}
        </p>
        <p class="text-xs text-slate-400 mt-2">
          Ticket médio: {{ fmt(kpis.ticket_medio) }}
        </p>
      </div>

      <!-- Pagas / Averbadas -->
      <div class="rounded-xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-800 p-5">
        <div class="flex items-start justify-between mb-3">
          <span class="text-sm text-slate-500 dark:text-slate-400 font-medium">Pagas / Averbadas</span>
          <span class="i-lucide-wallet text-slate-400 text-lg" />
        </div>
        <p class="text-2xl font-bold text-slate-800 dark:text-slate-100">
          {{ fmt(kpis.pagas_valor) }}
        </p>
        <p class="text-xs text-slate-400 mt-2">
          {{ fmtN(kpis.pagas_count) }} propostas ({{ kpis.percent_pagas }}% do total)
        </p>
      </div>

      <!-- Projeção -->
      <div class="rounded-xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-800 p-5">
        <div class="flex items-start justify-between mb-3">
          <span class="text-sm text-slate-500 dark:text-slate-400 font-medium">Projeção do Mês</span>
          <span class="i-lucide-trending-up text-slate-400 text-lg" />
        </div>
        <p class="text-2xl font-bold text-slate-800 dark:text-slate-100">
          {{ fmt(kpis.projecao) }}
        </p>
        <p class="text-xs text-slate-400 mt-2">
          Projeção linear · mês atual
        </p>
      </div>

      <!-- Produção Total -->
      <div class="rounded-xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-800 p-5">
        <div class="flex items-start justify-between mb-3">
          <span class="text-sm text-slate-500 dark:text-slate-400 font-medium">Produção Total</span>
          <span class="i-lucide-dollar-sign text-slate-400 text-lg" />
        </div>
        <p class="text-2xl font-bold text-slate-800 dark:text-slate-100">
          {{ fmt(kpis.producao_total) }}
        </p>
        <p class="text-xs text-slate-400 mt-2">
          Valor líquido: {{ fmt(kpis.valor_liquido_total) }}
        </p>
      </div>

    </div>

    <!-- Refresh -->
    <div v-if="kpis" class="mt-4 flex justify-end">
      <button
        class="text-xs text-slate-400 hover:text-slate-600 flex items-center gap-1"
        :disabled="loading"
        @click="fetchKpis"
      >
        <span class="i-lucide-refresh-cw" />
        Atualizar
      </button>
    </div>
  </div>
</template>
