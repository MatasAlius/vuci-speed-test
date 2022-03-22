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
    <a-divider />
    <gauge
      :heading="gauge.title"
      :min="0"
      :max="gauge.max"
      :value="gauge.value"
      :valueToExceedLimits="true"
      activeFill="red"
      :inactiveFill="gauge.color"
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
  </div>
</template>

<script>
import { Gauge } from '@chrisheanan/vue-gauge'
import Location from './components/Location'
import ServerList from './components/ServerList'

export default {
  components: {
    Gauge,
    Location,
    ServerList
  },
  data () {
    return {
      currentStep: 0,
      inputServer: 'best',
      gauge: {
        value: 0,
        title: '',
        color: 'green',
        max: 100
      },
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
  timers: {
    uploadReadFile: { name: 'uploadReadFile', time: 1000, autostart: false, immediate: true, repeat: true },
    downloadReadFile: { name: 'downloadReadFile', time: 1000, autostart: false, immediate: true, repeat: true }
  },
  created () {
    console.log(sessionStorage.getItem('server'))
    this.getServerList()
  },
  methods: {
    startTest () {
      if (this.selectedServer.id === -1) {
        this.gauge.title = 'Searching for best server'
      } else {
        this.connection.icon = 'loading'
        this.connection.description = 'Connecting'
        this.upload.description = ''
        this.currentStep = 0
        this.gauge.value = 0
        this.gauge.color = 'green'
        this.gauge.title = this.serverList[this.selectedServer.id].name + ' ' + this.serverList[this.selectedServer.id].sponsor
        this.$rpc.call('speedtest', 'speedTestCurl', { url: this.serverList[this.selectedServer.id].url, size: 1024 }).then(r => {
          if (r) {
            if (r.ok) {
              this.connection.description = 'Latency: ' + r.connect + ' s'
              this.connection.icon = 'check'
              this.upload.icon = 'check'
              this.currentStep = 1
              this.downloadTest()
            } else {
              this.connection.description = 'Error'
              this.connection.icon = 'disconnect'
            }
          } else {
            this.connection.description = 'Error'
            this.connection.icon = 'disconnect'
          }
        })
      }
    },
    uploadTest () {
      this.$rpc.call('speedtest', 'speedTestUpload', { url: this.serverList[this.selectedServer.id].url, size: 50485760 }).then(r => {
        this.upload.icon = 'loading'
        this.$timer.start('uploadReadFile')
      })
    },
    uploadReadFile () {
      this.$rpc.call('speedtest', 'readAllFile', { path: '/tmp/speedtest_up.txt' }).then(r => {
        if (r && r.length > 0) {
          const res = r[0].split(',')
          this.upload.description = 'Speed: ' + (+res[3]).toFixed(2) + ' MB/s'
          if (this.gauge.max < +res[3]) {
            this.gauge.max = +((+res[3]).toFixed(0))
          }
          this.gauge.value = +res[3]
          this.currentStep = 2
          if (res[1] !== 0 && res[1] === res[2]) {
            this.$timer.stop('uploadReadFile')
            this.upload.icon = 'upload'
            this.gauge.value = 0
          }
        }
      })
    },
    downloadTest () {
      this.$rpc.call('speedtest', 'speedTestDownload', { url: this.serverList[this.selectedServer.id].host + '/download' }).then(r => {
        this.download.icon = 'loading'
        this.$timer.start('downloadReadFile')
      })
    },
    downloadReadFile () {
      this.$rpc.call('speedtest', 'readAllFile', { path: '/tmp/speedtest_down.txt' }).then(r => {
        if (r && r.length > 0) {
          const res = r[0].split(',')
          this.download.description = 'Speed: ' + (+res[3]).toFixed(2) + ' MB/s'
          if (this.gauge.max < +res[3]) {
            this.gauge.max = +((+res[3]).toFixed(0))
          }
          this.gauge.value = +res[3]
          this.currentStep = 1
          if (res[1] !== 0 && res[1] === res[2]) {
            this.$timer.stop('downloadReadFile')
            this.download.icon = 'download'
            this.currentStep = 2
            this.gauge.value = 0
            this.gauge.color = 'blue'
            this.uploadTest()
          }
        }
      })
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
              if (!sessionStorage.getItem('server')) {
                if (this.user_code === xmlServer[0].getAttribute('cc')) {
                  this.speedTestCurl(xmlServer[0].getAttribute('url'), count)
                }
              } else if (+count === +sessionStorage.getItem('server')) {
                this.selectedServer.id = sessionStorage.getItem('server')
                this.selectedServer.name = 'Best server (' + this.serverList[this.selectedServer.id].name + ')'
                this.selectedServer.icon = 'dashboard'
              }
              count++
            }
          }
        }
      })
    },
    speedTestCurl (url, index) {
      this.$rpc.call('speedtest', 'speedTestCurl', { url: url, size: 1024 }).then(r => {
        if (r.ok) {
          this.serverUserCountry.push({ key: index, total: r.total })
          if (this.selectedServer.id > -1) {
            if (this.selectedServer.total > r.total) {
              this.selectedServer.id = index
              this.selectedServer.name = 'Best server (' + this.serverList[index].name + ')'
              this.selectedServer.total = r.total
              sessionStorage.setItem('server', index)
            }
          } else {
            this.selectedServer.id = index
            this.selectedServer.name = 'Best server (' + this.serverList[index].name + ')'
            this.selectedServer.total = r.total
            sessionStorage.setItem('server', index)
          }
        }
        this.selectedServer.icon = 'dashboard'
      })
    }
  }
}
</script>
