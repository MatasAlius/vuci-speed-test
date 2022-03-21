<template>
  <div class="speed-test">
    <a-row :gutter="16">
      <location @cc="getLocation" />
      <a-col :span="8">
        <a-card title="Speed test" style="width: 400px" :bordered="false">
          <a-form @submit.prevent="startTest" :label-col="{ span: 8 }" :wrapper-col="{ span: 4 }">
            <a-form-item label="Choose server">
              <a-button @click="btnSelect"><a-icon :type="selectedServer.icon"/>{{ selectedServer.name }}</a-button>
            </a-form-item>
            <a-form-item>
              <a-button type="primary" html-type="submit" size="large">
                <a-icon type="play-circle" />Start
              </a-button>
            </a-form-item>
          </a-form>
        </a-card>
      </a-col>
    </a-row>

    <gauge
      :heading="gaugeTitle"
      :min="0"
      :max="100"
      :value="gaugeValue"
      :valueToExceedLimits="true"
      activeFill="red"
      inactiveFill="green"
    />
    <a-steps :current="currentStep">
      <a-step :title="connection.title" :description="connection.description">
        <a-icon slot="icon" :type="connection.icon" />
      </a-step>
      <a-step :title="download.title" :description="download.description">
        <a-icon slot="icon" :type="download.icon" />
      </a-step>
      <a-step :title="upload.title" :description="upload.description">
        <a-icon slot="icon" :type="upload.icon" />
      </a-step>
    </a-steps>

    <a-divider />

    <a-modal v-model="serverListModal" :width="800" @cancel="closeModal()">
      <server-list :serverList="serverList" @selectServer="selectServer" />
      <template #footer><div/></template>
    </a-modal>

    {{ user_code }}

    {{ selectedServer }}
    <br />
    Latencies:
    {{ serverUserCountry }} {{ serverUserCountry.length }}
    <a-divider />
  </div>
</template>

<script>
import { Gauge } from '@chrisheanan/vue-gauge'
import Location from './components/Location'
import ServerList from './components/ServerList'

const columns = [
  {
    title: 'Name',
    dataIndex: 'name',
    key: 'name',
    scopedSlots: { customRender: 'name' }
  },
  {
    title: 'Country',
    dataIndex: 'country',
    key: 'country'
  },
  {
    title: 'Sponsor',
    dataIndex: 'sponsor',
    key: 'sponsor'
  },
  {
    scopedSlots: { customRender: 'button' }
  }
]

export default {
  components: {
    Gauge,
    Location,
    ServerList
  },
  data () {
    return {
      columns,
      time: '',
      currentStep: 0,
      inputServer: 'best',
      gaugeValue: 0,
      gaugeTitle: 'Begin speed test',
      user_code: '',
      serverList: [],
      serverListModal: false,
      selectedServer: {
        id: -1,
        name: 'Best server',
        total: -1,
        icon: 'loading'
      },
      serverUserCountry: [],
      connection: {
        title: 'Connection',
        icon: 'play-circle',
        description: 'Begin speed test'
      },
      upload: {
        title: 'Upload',
        icon: 'upload',
        description: ''
      },
      download: {
        title: 'Download',
        icon: 'download',
        description: ''
      }
    }
  },
  filters: {
    toMB: function (value) {
      return (value / 1000000).toFixed(2)
    }
  },
  created () {
    this.getServerList()
  },
  methods: {
    startTest () {
      console.log('startTest')
      if (this.selectedServer.id === -1) {
        console.log('Searching for best server')
      } else {
        console.log('Selected server: ' + this.selectedServer.name + ' , ' + this.selectedServer.id)
        this.connection.icon = 'loading'
        this.connection.description = 'Connecting'
        this.upload.icon = 'upload'
        this.upload.description = ''
        // 1048576 - 1MB
        // 10485760 - 10MB
        this.$rpc.call('speedtest', 'speedTestCurl', { url: this.serverList[this.selectedServer.id].url, size: 5048576 }).then(r => {
          console.log(r)
          if (r.ok) {
            this.connection.icon = 'check'
            this.connection.description = 'Connected'
            this.upload.icon = 'check'
            this.upload.description = 'Upload speed: ' + this.$options.filters.toMB(r.upload) + 'MB/s'
            this.gaugeValue = +this.$options.filters.toMB(r.upload)
            this.currentStep = 2
          } else {
            this.connection.icon = 'disconnect'
            this.connection.description = 'Error'
          }
        })
      }
    },
    btnSelect () {
      this.serverListModal = true
    },
    closeModal () {
      this.serverListModal = false
    },
    selectServer (e) {
      this.serverListModal = false
      this.selectedServer.name = this.serverList[e].name + ' ' + this.serverList[e].sponsor
      this.selectedServer.id = e
    },
    getLocation (e) {
      this.user_code = e
    },
    getServerList () {
      this.$rpc.call('speedtest', 'getServerList', { }).then(data => {
        this.getReadFile()
      })
    },
    getReadFile () {
      this.serverList = []
      this.$rpc.call('speedtest', 'readFile', { from: 1, to: 6938 }).then(data => {
        if (data) {
          var parser = new DOMParser()
          var count = 0
          for (var i = 0; i < data.length; i++) {
            var xmlDoc = parser.parseFromString(data[i], 'text/xml')
            var xmlServer = xmlDoc.getElementsByTagName('server')
            if (xmlServer[0]) {
              this.serverList.push({ key: count, name: xmlServer[0].getAttribute('name'), url: xmlServer[0].getAttribute('url'), country: xmlServer[0].getAttribute('country'), sponsor: xmlServer[0].getAttribute('sponsor'), host: xmlServer[0].getAttribute('host') })
              if (this.user_code === xmlServer[0].getAttribute('cc')) {
                this.speedTestCurl(xmlServer[0].getAttribute('url'), count)
              }
              count++
            }
          }
        }
      })
    },
    speedTestCurl (url, index) {
      this.$rpc.call('speedtest', 'speedTestCurl', { url: url, size: 1024 }).then(r => {
        console.log(r)
        if (r.ok) {
          this.serverUserCountry.push({ key: index, total: r.total })
          if (this.selectedServer.id > -1) {
            if (this.selectedServer.total > r.total) {
              this.selectedServer.id = index
              this.selectedServer.name = 'Best server (' + this.serverList[index].name + ')'
              this.selectedServer.total = r.total
            }
          } else {
            this.selectedServer.id = index
            this.selectedServer.name = 'Best server (' + this.serverList[index].name + ')'
            this.selectedServer.total = r.total
          }
        }
        this.selectedServer.icon = 'dashboard'
      })
    }
  }
}
</script>
