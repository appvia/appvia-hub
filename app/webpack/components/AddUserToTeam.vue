<template>
  <div class="p-3">
    <span class="font-weight-bold mr-2">
      Add user:
    </span>
    <autocomplete
      class="d-inline-block"
      style="width: 400px;"
      :search="search"
      placeholder="Find user to add to team"
      aria-label="Find user to add to team"
      :get-result-value="getResultValue"
      @submit="handleSubmit"
    ></autocomplete>
  </div>
</template>

<script>
import Turbolinks from 'turbolinks';
import Autocomplete from '@trevoreyre/autocomplete-vue';
import axios from 'axios';

import csfrTokenMixin from './mixins/csrfTokenMixin';

export default {
  components: {
    Autocomplete
  },
  mixins: [csfrTokenMixin],
  props: {
    teamId: {
      type: String,
      required: true
    },
    teamUrl: {
      type: String,
      required: true
    }
  },
  methods: {
    search(input) {
      if (input.length < 1) {
        return [];
      }

      return axios
        .get('/users/search', { params: { q: input } })
        .then(result => result.data);
    },
    getResultValue(result) {
      return result.email;
    },
    handleSubmit(result) {
      return axios
        .put(
          `/teams/${this.teamId}/memberships/${result.id}`,
          {
            role: null
          },
          {
            headers: {
              'X-CSRF-TOKEN': this.csrfToken,
              Accept: 'application/json'
            }
          }
        )
        .then(() => {
          Turbolinks.clearCache();
          Turbolinks.visit(this.teamUrl);
        });
    }
  }
};
</script>
