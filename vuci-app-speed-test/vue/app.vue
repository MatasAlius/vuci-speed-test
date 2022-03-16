<template>
  <div class="speed-test">
    <a-row :gutter="16">
      <a-col :span="8">
        <a-card title="Information" style="width: 400px" :bordered="false">
          <h4>Public IP address: {{ user_ip }}</h4>
          <h4>Country: {{ user_country }}</h4>
          <h4>City: {{ user_city }}</h4>
          <h4>ISP: {{ user_isp }}</h4>
        </a-card>
      </a-col>
      <a-col :span="8">
        <a-card title="Speed test" style="width: 400px" :bordered="false">
          <a-form @submit.prevent="startTest" :label-col="{ span: 8 }" :wrapper-col="{ span: 4 }">
            <a-form-item label="Choose server">
              <a-button @click="btnSelect"><a-icon type="dashboard" />{{ selectedServer.name }}</a-button>
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
    <a-icon slot="icon" type="disconnect" />
    <a-icon slot="icon" type="check" />
    <a-steps :current="currentStep">
      <a-step title="Connecting" description="This is a connecting description.">
        <a-icon slot="icon" type="loading" />
      </a-step>
      <a-step title="Downlaod" description="This is a download description.">
        <a-icon slot="icon" type="download" />
      </a-step>
      <a-step title="Upload" description="This is a upload description.">
        <a-icon slot="icon" type="upload" />
      </a-step>
    </a-steps>

    <a-divider />

    <a-modal v-model="serverListModal" :width="800" title="Choose server" @cancel="btnSelect" :footer="null" :sorter="true">
      <a-table :columns="columns" :data-source="serverList">
        <span slot="name" slot-scope="text">
          <template> {{ text }}</template>
        </span>
        <span slot="country" slot-scope="text">
          <template> {{ text }}</template>
        </span>
        <span slot="sponsor" slot-scope="text">
          <template> {{ text }}</template>
        </span>
        <span slot="button" slot-scope="text, record">
          <a-button type="primary" ghost @click="selectServer(record.key, record.name)">Select</a-button>
        </span>
      </a-table>
    </a-modal>

    {{ serverUserCountry }} {{ serverUserCountry.length }}

    <a-divider />

    <!-- {{ serverList }} -->
  </div>
</template>

<script>
import { Gauge } from '@chrisheanan/vue-gauge'

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
    Gauge
  },
  data () {
    return {
      columns,
      time: '',
      currentStep: 2,
      inputServer: 'best',
      gaugeValue: 20,
      gaugeTitle: 'Begin speed test',
      user_ip: '',
      user_country: '',
      user_city: '',
      user_isp: '',
      user_code: '',
      serverList: [],
      serverListModal: false,
      selectedServer: {
        id: -1,
        name: 'Best server'
      },
      serverUserCountry: []
    }
  },
  created () {
    this.getLocation()
    this.getServerList()
    // this.getReadFile()
    // var url = 'http://speedtest.lixp.lt/speedtest/upload.php'
    // this.$rpc.call('speedtest', 'speedTestCurl', { url: url }).then(r => {
    //   console.log('Res:')
    //   console.log(r)
    // })
  },
  methods: {
    startTest () {
      console.log('startTest')
      if (this.selectedServer.id === -1) {
        console.log('Searching for best server')
      } else {
        console.log('Selected server: ' + this.selectedServer.name)
      }
    },
    btnSelect () {
      this.serverListModal = !this.serverListModal
    },
    selectServer (index, name) {
      console.log(index, name)
      console.log(this.serverList[index].url)
      this.serverListModal = false
      this.selectedServer.name = this.serverList[index].name + ' ' + this.serverList[index].sponsor
      this.selectedServer.id = index
    },
    getLocation () {
      this.$rpc.call('speedtest', 'getLocation', { }).then(data => {
        const results = JSON.parse(data.result)
        this.user_ip = results.ip
        this.user_country = results.country
        this.user_city = results.city
        this.user_isp = results.isp
        this.user_code = results.country_code
        console.log(this.user_city.normalize())
      })
    },
    getServerList () {
      this.$rpc.call('speedtest', 'getServerList', { }).then(data => {
        console.log(data)
        this.getReadFile()
      })
    },
    getReadFile () {
      this.serverList = []
      this.$rpc.call('speedtest', 'readFile', { from: 1, to: 6938 }).then(data => {
        if (data) {
          var parser = new DOMParser()
          console.log(data.length)
          var count = 0
          for (var i = 0; i < data.length; i++) {
            var xmlDoc = parser.parseFromString(data[i], 'text/xml')
            var xmlServer = xmlDoc.getElementsByTagName('server')
            if (xmlServer[0]) {
              this.serverList.push({ key: count, name: xmlServer[0].getAttribute('name'), url: xmlServer[0].getAttribute('url'), country: xmlServer[0].getAttribute('country'), sponsor: xmlServer[0].getAttribute('sponsor'), host: xmlServer[0].getAttribute('host') })
              if (this.user_code === xmlServer[0].getAttribute('cc')) {
                console.log(xmlServer[0].getAttribute('name'))
                this.serverUserCountry.push(count)
                this.speedTestCurl(xmlServer[0].getAttribute('url'))
              }
              count++
            }
            // console.log(i)
          }
        }
      })
      // this.$rpc.call('speedtest', 'readAllFile', { }).then(data => {
      //   console.log(data)
      // })
    },
    speedTestCurl (url) {
      console.log(url)
      this.$rpc.call('speedtest', 'speedTestCurl', { url: url }).then(r => {
        console.log(r)
      })
    }
  }
}
</script>
