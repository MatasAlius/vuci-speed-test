<template>
  <div class="location">
    <a-col :span="8">
      <a-card title="Information" style="width: 400px" :bordered="false">
        <h4>Public IP address: {{ user_ip }}</h4>
        <h4>Country: {{ user_country }}</h4>
        <h4>City: {{ user_city }}</h4>
        <h4>ISP: {{ user_isp }}</h4>
      </a-card>
    </a-col>
  </div>
</template>

<script>
export default {
  name: 'Location',
  data () {
    return {
      user_ip: '',
      user_country: '',
      user_city: '',
      user_isp: '',
      user_code: ''
    }
  },
  created () {
    this.getLocation()
  },
  methods: {
    getLocation () {
      this.$rpc.call('speedtest', 'getLocation', { }).then(data => {
        const results = JSON.parse(data.result)
        this.user_ip = results.ip
        this.user_country = results.country
        this.user_city = results.city
        this.user_isp = results.isp
        this.user_code = results.country_code
        this.$emit('cc', this.user_code)
      })
    }
  }
}
</script>
