<template>
  <div id="app">
    <Template/>
  </div>
</template>

<script>
import Template from './components/Template'

export default {
  name: 'App',
  components: {
    Template
  }
}
</script>

<style>
#app {
  font-family: 'Avenir', Helvetica, Arial, sans-serif;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
  color: #2c3e50;
}
</style>
