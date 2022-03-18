<template>
  <div class="serverlist">
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
  </div>
</template>

<script>

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
  name: 'ServerList',
  props: {
    serverList: Array
  },
  data () {
    return {
      columns
    }
  },
  methods: {
    selectServer (index, name) {
      console.log('index: ' + index + ' , ' + name)
      this.$emit('selectServer', index)
    }
  }
}
</script>
