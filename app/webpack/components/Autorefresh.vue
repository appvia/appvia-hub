<template>
  <div>
    Refreshing in {{ remainingSecs }}s…
    <a :href="stopRefreshUrl" class="ml-2">Stop</a>
  </div>
</template>

<script>
import Turbolinks from 'turbolinks';

export default {
  props: {
    intervalSecs: {
      type: Number,
      required: true
    },
    stopRefreshUrl: {
      type: String,
      required: true
    }
  },
  data() {
    return {
      remainingSecs: null,
      tickIntervalSecs: 1
    };
  },
  created() {
    this.remainingSecs = this.intervalSecs;

    this.intervalId = setInterval(this.tick, this.tickIntervalSecs * 1000);
  },
  beforeDestroy() {
    if (this.intervalId) {
      clearInterval(this.intervalId);
    }
  },
  methods: {
    tick() {
      if (this.remainingSecs === 0) {
        Turbolinks.visit(window.location.toString(), { action: 'replace' });
        // At this point the component will be destroyed and recreated in the new page load
      } else {
        this.remainingSecs -= 1;
      }
    }
  }
};
</script>

<style scoped></style>
