// Visit The Stimulus Handbook for more details
// https://stimulusjs.org/handbook/introduction

import { Controller } from 'stimulus';

export default class extends Controller {
  static targets = ['section', 'form'];

  initialize() {
    this.showCurrentSection();
  }

  setCurrentIntegration(event) {
    this.integrationId = event.currentTarget.value;
  }

  showCurrentSection() {
    this.sectionTargets.forEach(el => {
      /* eslint-disable-next-line prettier/prettier */
      const isSelectedIntegration = el.dataset.integrationId === this.integrationId;
      el.classList.toggle('d-none', !isSelectedIntegration);
      if (isSelectedIntegration) {
        el.removeAttribute('disabled');
      } else {
        el.setAttribute('disabled', 'disabled');
      }
    });
  }

  get integrationId() {
    return this.data.get('integrationId');
  }

  set integrationId(value) {
    this.data.set('integrationId', value);
    this.showCurrentSection();
  }

  submitForm() {
    this.formTarget.submit();
  }
}
