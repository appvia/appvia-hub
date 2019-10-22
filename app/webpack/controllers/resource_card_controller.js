// Visit The Stimulus Handbook for more details
// https://stimulusjs.org/handbook/introduction

import { Controller } from 'stimulus';

import axios from 'axios';

export default class extends Controller {
  PENDING_STATUS = 'Pending';

  WAIT_MS = 10000;

  static targets = ['status'];

  timer = null;

  connect() {
    this.triggerTimer();
  }

  disconnect() {
    if (this.timer) {
      clearTimeout(this.timer);
    }
  }

  get currentStatus() {
    return this.statusTarget.innerText;
  }

  get resourceUrl() {
    return this.data.get('resourceUrl');
  }

  triggerTimer() {
    if (this.currentStatus === this.PENDING_STATUS) {
      this.timer = setTimeout(() => this.refresh(), this.WAIT_MS);
    }
  }

  refresh() {
    return axios.get(this.resourceUrl).then(response => {
      this.element.innerHTML = response.data;
      this.triggerTimer();
    });
  }
}
