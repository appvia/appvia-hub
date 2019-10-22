<template>
  <div>
    <div v-if="['FETCH', 'ERROR'].includes(state)" class="row border m-0">
      <div class="col-12 p-1 ml-1">
        <span class="card-text text-muted">{{ getStateMessage() }}</span>
        <a v-if="state === 'ERROR'" href="#" @click.prevent @click="retry()">
          Retry
        </a>
      </div>
    </div>
    <!-- eslint-disable-next-line vue/require-v-for-key -->
    <div v-for="status in results">
      <a
        :href="status.url"
        target="_new"
        rel="noopener noreferrer"
        class="card-link ml-0"
      >
        <div class="row border m-0 bg-white">
          <div
            class="col-1 p-1 text-center text-white"
            :class="`bg-${status.colour}`"
          >
            {{ status.status }}
          </div>
          <div class="col-11 p-1">
            <div class="ml-2">
              <span class="card-text text-muted">{{ status.text }}</span>
            </div>
          </div>
        </div>
      </a>
    </div>
  </div>
</template>

<script>
import axios from 'axios';

const DELAY_MS = 5000;
const MAX_ATTEMPTS = 2;

export default {
  props: {
    resourceId: {
      type: String,
      required: true
    },
    projectId: {
      type: String,
      required: true
    }
  },
  data() {
    return {
      state: 'FETCH',
      delayBetweenAttempts: DELAY_MS,
      maxNumberOfAttempts: MAX_ATTEMPTS,
      numberOfAttempts: 0,
      results: []
    };
  },
  created() {
    this.setup();
  },
  methods: {
    setup() {
      this.getStatus().then(() => {
        if (this.state === 'FETCH') {
          setTimeout(this.setup, this.delayBetweenAttempts);
        }
      });
    },
    retry() {
      this.numberOfAttempts = 0;
      this.state = 'FETCH';
      this.setup();
    },
    isTimeout(result) {
      return result.data.length === 1 && result.data[0].status === 'Timeout';
    },
    handleGetStatusResult(result) {
      if (this.isTimeout(result)) {
        this.numberOfAttempts += 1;
        if (this.numberOfAttempts === this.maxNumberOfAttempts) {
          this.errorMessage = result.data[0].text;
          this.state = 'ERROR';
        }
        return;
      }
      this.results = result.data;
      this.state = 'SUCCESS';
    },
    handleGetStatusError() {
      this.numberOfAttempts += 1;
      if (this.numberOfAttempts === this.maxNumberOfAttempts) {
        this.state = 'ERROR';
      }
    },
    getStatus() {
      return axios
        .get(`/spaces/${this.projectId}/resources/${this.resourceId}/checks`)
        .then(this.handleGetStatusResult)
        .catch(this.handleGetStatusError);
    },
    getStateMessage() {
      return {
        FETCH: 'Fetching status checks...',
        ERROR: this.errorMessage
      }[this.state];
    }
  }
};
</script>

<style scoped></style>
