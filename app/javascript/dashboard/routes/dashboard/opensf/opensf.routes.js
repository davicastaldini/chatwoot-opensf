// OPENSF: rotas do módulo de agenda/tarefas
import { frontendURL } from '../../../helper/URLHelper';
import Agenda from './Agenda.vue';

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/opensf/agenda'),
      name: 'opensf_agenda',
      meta: {
        permissions: ['administrator', 'agent', 'custom_role'],
      },
      component: Agenda,
    },
  ],
};
