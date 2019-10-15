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

Rails.start();
Turbolinks.start();
LocalTime.start();

Vue.use(TurbolinksAdapter);

// Inject VueJS components
document.addEventListener('turbolinks:load', () => {
  const components = [
    {
      elementId: 'autorefresh',
      components: { Autorefresh },
      data: {}
    },
    {
      elementId: 'add-user-to-team',
      components: { AddUserToTeam },
      data: {}
    }
  ];

  components.forEach(e => {
    const element = document.getElementById(e.elementId);
    if (element != null) {
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

/* eslint-disable no-undef */
document.addEventListener('turbolinks:load', () => {
  $(function tooltipActivation() {
    $('[data-toggle="tooltip"]').tooltip();
  });

  const anchor = window.location.hash;
  $(`a[href="${anchor}"]`).tab('show');

  // Make bootstrap-select work with Turbolinks
  $(window).trigger('load.bs.select.data-api');
});

$(document).ready(function() {
  const clipboard = new ClipboardJS('.copy-btn');
  clipboard.on('success', function(e) {
    const { originalTitle } = e.trigger.dataset;
    $(e.trigger)
      .attr('data-original-title', 'Copied!')
      .tooltip('show');
    $(e.trigger).attr('data-original-title', originalTitle);
  });
});
/* eslint-enable no-undef */
