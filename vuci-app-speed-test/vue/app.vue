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
              <a-button type="primary" html-type="submit" size="large" :disabled="disableStart">
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
      unit="Mbps"
      :unitOnArc="false"
      :pointerStrokeWidth="10"
      :pointerGap="2"
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
    <a-modal v-model="serverListModal" :width="600" @cancel="closeModal()">
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
      gauge: {
        value: 0,
        title: '',
        color: 'green',
        max: 100
      },
      user_code: '',
      serverList: [],
      serverListModal: false,
      disableStart: true,
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
        description: '',
        size: 41943040,
        count: 0
      },
      download: {
        title: 'Download',
        icon: 'download',
        description: ''
      }
    }
  },
  timers: {
    uploadReadFile: { name: 'uploadReadFile', time: 500, autostart: false, immediate: true, repeat: true },
    downloadReadFile: { name: 'downloadReadFile', time: 500, autostart: false, immediate: true, repeat: true }
  },
  created () {
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
        this.gauge.max = 100
        this.disableStart = true
        this.$rpc.call('speedtest', 'speedTest', { url: this.serverList[this.selectedServer.id].url, size: 1024, id: this.selectedServer.id }).then(data => {
          const delayPromise = new Promise((resolve, reject) => {
            setTimeout(() => {
              this.$rpc.call('speedtest', 'readAllFile', { path: '/tmp/speedtest_connect_' + this.selectedServer.id + '.txt' }).then(data => {
                if (data[0]) {
                  const res = data[0].split(',')
                  if (res[1] === 'true') {
                    this.connection.description = 'Latency: ' + (res[3] * 1000).toFixed(0) + ' ms'
                    this.connection.icon = 'check'
                    this.currentStep = 1
                    this.downloadTest()
                  } else {
                    this.connection.description = 'Error'
                    this.connection.icon = 'disconnect'
                    this.disableStart = false
                  }
                } else {
                  this.connection.description = 'Error'
                  this.connection.icon = 'disconnect'
                  this.disableStart = false
                }
              })
            }, 2000)
          })
          delayPromise.then()
        })
      }
    },
    uploadTest () {
      this.upload.count = 0
      this.$rpc.call('speedtest', 'speedTestUpload', { url: this.serverList[this.selectedServer.id].url, size: this.upload.size }).then(r => {
        this.upload.icon = 'loading'
        this.$timer.start('uploadReadFile')
      })
    },
    uploadReadFile () {
      this.$rpc.call('speedtest', 'readAllFile', { path: '/tmp/speedtest_up.txt' }).then(r => {
        if (r && r.length > 0) {
          const res = r[0].split(',')
          if (res[4] === '1') {
            this.$timer.stop('uploadReadFile')
            this.upload.icon = 'upload'
            if (this.gauge.value === 0) {
              if (this.upload.count >= 3) {
                this.upload.icon = 'disconnect'
                this.upload.description = 'Error'
                this.disableStart = false
              } else {
                this.upload.count = this.upload.count + 1
                this.$rpc.call('speedtest', 'speedTestUpload', { url: this.serverList[this.selectedServer.id].url, size: this.upload.size / 10 }).then(r => {
                  this.upload.icon = 'loading'
                  this.$timer.start('uploadReadFile')
                })
              }
            } else {
              this.gauge.value = 0
              this.disableStart = false
            }
          } else {
            this.upload.description = 'Speed: ' + (+res[3]).toFixed(2) + ' Mb/s'
            if (this.gauge.max < +res[3]) {
              this.gauge.max = +((+res[3]).toFixed(0))
            }
            this.gauge.value = +res[3]
          }
        }
      })
    },
    downloadTest () {
      this.$rpc.call('speedtest', 'speedTestDownload', { url: 'http://' + this.serverList[this.selectedServer.id].host + '/download' }).then(r => {
        this.download.icon = 'loading'
        this.$timer.start('downloadReadFile')
      })
    },
    downloadReadFile () {
      this.$rpc.call('speedtest', 'readAllFile', { path: '/tmp/speedtest_down.txt' }).then(r => {
        if (r && r.length > 0) {
          const res = r[0].split(',')
          if (res[4] === '1') {
            this.$timer.stop('downloadReadFile')
            this.download.icon = 'download'
            this.currentStep = 2
            if (this.gauge.value === 0) {
              this.download.icon = 'disconnect'
              this.download.description = 'Error'
            }
            this.gauge.value = 0
            this.gauge.color = 'blue'
            this.gauge.max = 100
            this.uploadTest()
          } else {
            this.download.description = 'Speed: ' + (+res[3]).toFixed(2) + ' Mb/s'
            if (this.gauge.max < +res[3]) {
              this.gauge.max = +((+res[3]).toFixed(0))
            }
            this.gauge.value = +res[3]
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
      this.disableStart = false
    },
    getServerList () {
      this.$rpc.call('speedtest', 'getServerList', { }).then(data => {
        this.getReadServerFile()
      })
    },
    getReadServerFile () {
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
                  this.$rpc.call('speedtest', 'speedTest', { url: xmlServer[0].getAttribute('url'), size: 1024, id: count }).then(data => {
                    const delayPromise = new Promise((resolve, reject) => {
                      setTimeout(() => {
                        this.$rpc.call('speedtest', 'readAllFile', { path: '/tmp/speedtest_connect_' + data.id + '.txt' }).then(data => {
                          if (data[0]) {
                            const res = data[0].split(',')
                            if (res[1] === 'true') {
                              this.serverUserCountry.push({ key: res[0], total: res[4] })
                              if (this.selectedServer.id > -1) {
                                if (this.selectedServer.total > res[4]) {
                                  this.selectedServer.id = res[0]
                                  this.selectedServer.name = 'Best server (' + this.serverList[res[0]].name + ')'
                                  this.selectedServer.total = res[4]
                                  sessionStorage.setItem('server', res[0])
                                }
                              } else {
                                this.selectedServer.id = res[0]
                                this.selectedServer.name = 'Best server (' + this.serverList[res[0]].name + ')'
                                this.selectedServer.total = res[4]
                                sessionStorage.setItem('server', res[0])
                              }
                              this.selectedServer.icon = 'dashboard'
                            }
                          }
                        })
                      }, 2000)
                    })
                    delayPromise.then()
                  })
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
    }
  }
}
</script>
