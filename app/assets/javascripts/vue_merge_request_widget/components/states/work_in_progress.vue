<script>
import $ from 'jquery';
import statusIcon from '../mr_widget_status_icon.vue';
import tooltip from '../../../vue_shared/directives/tooltip';
import eventHub from '../../event_hub';

export default {
  name: 'WorkInProgress',
  components: {
    statusIcon,
  },
  directives: {
    tooltip,
  },
  props: {
    mr: { type: Object, required: true },
    service: { type: Object, required: true },
  },
  data() {
    return {
      isMakingRequest: false,
    };
  },
  methods: {
    removeWIP() {
      this.isMakingRequest = true;
      this.service
        .removeWIP()
        .then(res => res.data)
        .then(data => {
          eventHub.$emit('UpdateWidgetData', data);
          new window.Flash('The merge request can now be merged.', 'notice'); // eslint-disable-line
          $('.merge-request .detail-page-description .title').text(this.mr.title);
        })
        .catch(() => {
          this.isMakingRequest = false;
          new window.Flash('Something went wrong. Please try again.'); // eslint-disable-line
        });
    },
  },
};
</script>

<template>
  <div class="mr-widget-body media">
    <status-icon
      :show-disabled-button="Boolean(mr.removeWIPPath)"
      status="warning"
    />
    <div class="media-body space-children">
      <span class="bold">
        This is a Work in Progress
        <i
          v-tooltip
          class="fa fa-question-circle"
          title="When this merge request is ready,
          remove the WIP: prefix from the title to allow it to be merged"
          aria-label="When this merge request is ready,
          remove the WIP: prefix from the title to allow it to be merged">
        </i>
      </span>
      <button
        v-if="mr.removeWIPPath"
        :disabled="isMakingRequest"
        type="button"
        class="btn btn-default btn-sm js-remove-wip"
        @click="removeWIP">
        <i
          v-if="isMakingRequest"
          class="fa fa-spinner fa-spin"
          aria-hidden="true">
        </i>
        Resolve WIP status
      </button>
    </div>
  </div>
</template>
