<script>
import LoadingState from 'dashboard/components/widgets/LoadingState.vue';

export default {
  components: {
    LoadingState,
  },
  props: {
    config: {
      type: Array,
      default: () => [],
    },
    currentChat: {
      type: Object,
      default: () => ({}),
    },
    isVisible: {
      type: Boolean,
      default: false,
    },
    position: {
      type: Number,
      required: true,
    },
  },
  data() {
    return {
      hasOpenedAtleastOnce: false,
      iframeLoading: true,
    };
  },
  computed: {
    dashboardAppContext() {
      return {
        conversation: this.currentChat,
        contact: this.$store.getters['contacts/getContact'](this.contactId),
        currentAgent: this.currentAgent,
      };
    },
    contactId() {
      return this.currentChat?.meta?.sender?.id;
    },
    currentAgent() {
      const { id, name, email } = this.$store.getters.getCurrentUser;
      return { id, name, email };
    },
  },
  watch: {
    isVisible() {
      if (this.isVisible) {
        this.hasOpenedAtleastOnce = true;
      }
    },
  },
  mounted() {
    window.addEventListener('message', this.triggerEvent);
  },
  unmounted() {
    window.removeEventListener('message', this.triggerEvent);
  },
  methods: {
    triggerEvent(event) {
      if (!this.isVisible) return;
      if (event.data === 'chatwoot-dashboard-app:fetch-info') {
        this.onIframeLoad(0);
      }
    },
    getFrameId(index) {
      return `dashboard-app--frame-${this.position}-${index}`;
    },
    frameUrl(url) {
      if (!url) return '';

      try {
        const frameUrl = new URL(url, window.location.origin);
        const isInsecureOpensfPage =
          window.location.protocol === 'https:' &&
          frameUrl.protocol === 'http:' &&
          frameUrl.pathname.startsWith('/opensf/');

        if (isInsecureOpensfPage) {
          return `${window.location.origin}${frameUrl.pathname}${frameUrl.search}${frameUrl.hash}`;
        }
      } catch {
        return url;
      }

      return url;
    },
    onIframeLoad(index) {
      // A possible alternative is to use ref instead of document.getElementById
      // However, when ref is used together with v-for, the ref you get will be
      // an array containing the child components mirroring the data source.
      const frameElement = document.getElementById(this.getFrameId(index));
      const eventData = { event: 'appContext', data: this.dashboardAppContext };
      frameElement.contentWindow.postMessage(JSON.stringify(eventData), '*');
      this.iframeLoading = false;
    },
  },
};
</script>

<!-- eslint-disable-next-line vue/no-root-v-if -->
<template>
  <!-- OPENSF UI: reversible visual frame for dashboard apps inside the agent workspace. -->
  <div
    v-if="hasOpenedAtleastOnce"
    class="opensf-dashboard-app-frame dashboard-app--container"
  >
    <div
      v-for="(configItem, index) in config"
      :key="index"
      class="dashboard-app--list"
    >
      <LoadingState
        v-if="iframeLoading"
        :message="$t('DASHBOARD_APPS.LOADING_MESSAGE')"
        class="dashboard-app_loading-container"
      />
      <iframe
        v-if="configItem.type === 'frame' && configItem.url"
        :id="getFrameId(index)"
        :src="frameUrl(configItem.url)"
        @load="() => onIframeLoad(index)"
      />
    </div>
  </div>
</template>

<style scoped>
.dashboard-app--container,
.dashboard-app--list,
.dashboard-app--list iframe {
  height: 100%;
  width: 100%;
}

.dashboard-app--list iframe {
  border: 0;
}
.dashboard-app_loading-container {
  display: flex;
  align-items: center;
  justify-content: center;
  height: 100%;
  width: 100%;
}
</style>
