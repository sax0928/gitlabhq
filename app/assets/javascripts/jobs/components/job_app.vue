<script>
  import _ from 'underscore';
  import { mapGetters, mapState, mapActions } from 'vuex';
  import { isScrolledToBottom } from '~/lib/utils/scroll_utils';
  import bp from '~/breakpoints';
  import CiHeader from '~/vue_shared/components/header_ci_component.vue';
  import Callout from '~/vue_shared/components/callout.vue';
  import createStore from '../store';
  import EmptyState from './empty_state.vue';
  import EnvironmentsBlock from './environments_block.vue';
  import ErasedBlock from './erased_block.vue';
  import Log from './job_log.vue';
  import LogTopBar from './job_log_controllers.vue';
  import StuckBlock from './stuck_block.vue';
  import Sidebar from './sidebar.vue';

  export default {
    name: 'JobPageApp',
    store: createStore(),
    components: {
      CiHeader,
      Callout,
      EmptyState,
      EnvironmentsBlock,
      ErasedBlock,
      Log,
      LogTopBar,
      StuckBlock,
      Sidebar,
    },
    props: {
      runnerSettingsUrl: {
        type: String,
        required: false,
        default: null,
      },
      runnerHelpUrl: {
        type: String,
        required: false,
        default: null,
      },
      endpoint: {
        type: String,
        required: true,
      },
      terminalPath: {
        type: String,
        required: false,
        default: null,
      },
      pagePath: {
        type: String,
        required: true,
      },
      logState: {
        type: String,
        required: true,
      },
    },
    computed: {
      ...mapState([
        'isLoading',
        'job',
        'isSidebarOpen',
        'trace',
        'isTraceComplete',
        'traceSize',
        'isTraceSizeVisible',
        'isScrollBottomDisabled',
        'isScrollTopDisabled',
        'isScrolledToBottomBeforeReceivingTrace',
        'hasError',
      ]),
      ...mapGetters([
        'headerActions',
        'headerTime',
        'shouldRenderCalloutMessage',
        'shouldRenderTriggeredLabel',
        'hasEnvironment',
        'isJobStuck',
        'hasTrace',
        'emptyStateIllustration',
        'isScrollingDown',
        'emptyStateAction',
      ]),

      shouldRenderContent() {
        return !this.isLoading && !this.hasError;
      }
    },
    watch: {
      // Once the job log is loaded,
      // fetch the stages for the dropdown on the sidebar
      job(newVal, oldVal) {
        if (_.isEmpty(oldVal) && !_.isEmpty(newVal.pipeline)) {
          this.fetchStages();
        }
      },
    },
    created() {
      this.throttled = _.throttle(this.toggleScrollButtons, 100);

      this.setJobEndpoint(this.endpoint);
      this.setTraceOptions({
        logState: this.logState,
        pagePath: this.pagePath,
      });

      this.fetchJob();
      this.fetchTrace();

      window.addEventListener('resize', this.onResize);
      window.addEventListener('scroll', this.updateScroll);
    },

    mounted() {
      this.updateSidebar();
    },

    destroyed() {
      window.removeEventListener('resize', this.onResize);
      window.removeEventListener('scroll', this.updateScroll);
    },

    methods: {
      ...mapActions([
        'setJobEndpoint',
        'setTraceOptions',
        'fetchJob',
        'fetchStages',
        'hideSidebar',
        'showSidebar',
        'toggleSidebar',
        'fetchTrace',
        'scrollBottom',
        'scrollTop',
        'toggleScrollButtons',
        'toggleScrollAnimation',
      ]),
      onResize() {
        this.updateSidebar();
        this.updateScroll();
      },
      updateSidebar() {
        if (bp.getBreakpointSize() === 'xs') {
          this.hideSidebar();
        } else if (!this.isSidebarOpen) {
          this.showSidebar();
        }
      },
      updateScroll() {
        if (!isScrolledToBottom()) {
          this.toggleScrollAnimation(false);
        } else if (this.isScrollingDown) {
          this.toggleScrollAnimation(true);
        }

        this.throttled();
      },
    },
  };
</script>
<template>
  <div>
    <gl-loading-icon
      v-if="isLoading"
      :size="2"
      class="js-job-loading qa-loading-animation prepend-top-20"
    />

    <template v-else-if="shouldRenderContent">
      <div class="js-job-content build-page">
        <!-- Header Section -->
        <header>
          <div class="js-build-header build-header top-area">
            <ci-header
              :status="job.status"
              :item-id="job.id"
              :time="headerTime"
              :user="job.user"
              :actions="headerActions"
              :has-sidebar-button="true"
              :should-render-triggered-label="shouldRenderTriggeredLabel"
              :item-name="__('Job')"
              @clickedSidebarButton="toggleSidebar"
            />
          </div>

          <callout
            v-if="shouldRenderCalloutMessage"
            :message="job.callout_message"
          />
        </header>
        <!-- EO Header Section -->

        <!-- Body Section -->
        <stuck-block
          v-if="isJobStuck"
          class="js-job-stuck"
          :has-no-runners-for-project="job.runners.available"
          :tags="job.tags"
          :runners-path="runnerSettingsUrl"
        />

        <environments-block
          v-if="hasEnvironment"
          class="js-job-environment"
          :deployment-status="job.deployment_status"
          :icon-status="job.status"
        />

        <erased-block
          v-if="job.erased_at"
          class="js-job-erased-block"
          :user="job.erased_by"
          :erased-at="job.erased_at"
        />

        <!--job log -->
        <div
          v-if="hasTrace"
          class="build-trace-container prepend-top-default">
          <log-top-bar
            :class="{
              'sidebar-expanded': isSidebarOpen,
              'sidebar-collapsed': !isSidebarOpen
            }"
            :erase-path="job.erase_path"
            :size="traceSize"
            :raw-path="job.raw_path"
            :is-scroll-bottom-disabled="isScrollBottomDisabled"
            :is-scroll-top-disabled="isScrollTopDisabled"
            :is-trace-size-visible="isTraceSizeVisible"
            :is-scrolling-down="isScrollingDown"
            @scrollJobLogTop="scrollTop"
            @scrollJobLogBottom="scrollBottom"
          />
          <log
            :trace="trace"
            :is-complete="isTraceComplete"
          />
        </div>
        <!-- EO job log -->

        <!--empty state -->
        <empty-state
          v-if="!hasTrace"
          class="js-job-empty-state"
          :illustration-path="emptyStateIllustration.image"
          :illustration-size-class="emptyStateIllustration.size"
          :title="emptyStateIllustration.title"
          :content="emptyStateIllustration.content"
          :action="emptyStateAction"
        />
      <!-- EO empty state -->

      <!-- EO Body Section -->
      </div>
    </template>

    <sidebar
      v-if="shouldRenderContent"
      class="js-job-sidebar"
      :class="{
        'right-sidebar-expanded': isSidebarOpen,
        'right-sidebar-collapsed': !isSidebarOpen
      }"
      :runner-help-url="runnerHelpUrl"
    />
  </div>
</template>
