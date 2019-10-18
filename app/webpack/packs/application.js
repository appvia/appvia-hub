import '../stylesheets/application.scss';
import '@trevoreyre/autocomplete-vue/dist/style.css';

import Rails from 'rails-ujs';
import Turbolinks from 'turbolinks';

import LocalTime from 'local-time';

import 'bootstrap/dist/js/bootstrap';
import 'bootstrap-select';
import 'data-confirm-modal';

import ClipboardJS from 'clipboard';

import '../gem-dependencies.js.erb';

import '../controllers';

import Vue from 'vue/dist/vue.esm';
import TurbolinksAdapter from 'vue-turbolinks';
import Autorefresh from '../components/Autorefresh.vue';
import AddUserToTeam from '../components/AddUserToTeam.vue';
import ResourceChecks from '../components/ResourceChecks.vue';

Rails.start();
Turbolinks.start();
LocalTime.start();

Vue.use(TurbolinksAdapter);

// Inject VueJS components
document.addEventListener('turbolinks:load', () => {
  const components = [
    {
      elementSelector: '#autorefresh',
      components: { Autorefresh },
      data: {}
    },
    {
      elementSelector: '#add-user-to-team',
      components: { AddUserToTeam },
      data: {}
    },
    {
      elementSelector: '.resource-checks',
      components: { ResourceChecks },
      data: {}
    }
  ];

  components.forEach(e => {
    const elems = document.querySelectorAll(e.elementSelector);
    elems.forEach(element => {
      if (element !== null) {
        /* eslint-disable no-unused-vars */
        const app = new Vue({
          el: element,
          components: e.components,
          data: e.data
        });
        /* eslint-enable no-unused-vars */
      }
    });
  });
});

/* eslint-disable no-undef */
document.addEventListener('turbolinks:load', () => {
  $(function tooltipActivation() {
    $('[data-toggle="tooltip"]').tooltip();
  });

  const anchor = window.location.hash;
  $(`a[href="${anchor}"]`).tab('show');

  // Make bootstrap-select work with Turbolinks
  $(window).trigger('load.bs.select.data-api');

  const clipboard = new ClipboardJS('.copy-btn');
  clipboard.on('success', function clipboardSuccess(e) {
    const { originalTitle } = e.trigger.dataset;
    $(e.trigger)
      .attr('data-original-title', 'Copied!')
      .tooltip('show');
    $(e.trigger).attr('data-original-title', originalTitle);
  });
});
/* eslint-enable no-undef */
