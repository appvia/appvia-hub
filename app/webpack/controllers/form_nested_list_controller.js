// Visit The Stimulus Handbook for more details
// https://stimulusjs.org/handbook/introduction

import { Controller } from 'stimulus';

export default class extends Controller {
  static targets = ['template', 'links'];

  nestedObjectClass = 'nested-object';

  add(event) {
    event.preventDefault();

    const content = this.templateTarget.innerHTML;
    this.linksTarget.insertAdjacentHTML('beforebegin', content);
  }

  remove(event) {
    event.preventDefault();

    const nestedObject = event.target.closest(`.${this.nestedObjectClass}`);
    nestedObject.remove();
  }
}
