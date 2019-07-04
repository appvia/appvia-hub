// Visit The Stimulus Handbook for more details
// https://stimulusjs.org/handbook/introduction

import { Controller } from 'stimulus';

export default class extends Controller {
  static targets = ['section'];

  initialize() {
    this.showCurrentSection();
  }

  setCurrentIntegration(event) {
    this.integrationId = event.currentTarget.value;
  }

  showCurrentSection() {
    this.sectionTargets.forEach(el => {
      el.classList.toggle(
        'd-none',
        el.dataset.integrationId !== this.integrationId
      );
    });
  }

  get integrationId() {
    return this.data.get('integrationId');
  }

  set integrationId(value) {
    this.data.set('integrationId', value);
    this.showCurrentSection();
  }
}
